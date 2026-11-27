package com.example.reading_sanctuary_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.security.MessageDigest
import java.util.ArrayDeque
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL_NAME = "reading_sanctuary/saf"
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 4242
    }

    private var pendingFolderPickerResult: MethodChannel.Result? = null
    private val backgroundExecutor = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val activeStreamSessions = ConcurrentHashMap<String, InputStream>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "openDocumentTree" -> handleOpenDocumentTree(result)
                    "getPersistedUriPermissions" -> handleGetPersistedUriPermissions(result)
                    "isUriPermissionGranted" -> handleIsUriPermissionGranted(call, result)
                    "releasePersistableUriPermission" -> handleReleasePersistableUriPermission(call, result)
                    "listFiles" -> handleListFiles(call, result)
                    "readFileHeader" -> handleReadFileHeader(call, result)
                    "computeDocumentSha256" -> handleComputeDocumentSha256(call, result)
                    "readDocumentBytes" -> handleReadDocumentBytes(call, result)
                    "openDocumentStream" -> handleOpenDocumentStream(call, result)
                    "readDocumentStreamChunk" -> handleReadDocumentStreamChunk(call, result)
                    "closeDocumentStream" -> handleCloseDocumentStream(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleOpenDocumentTree(result: MethodChannel.Result) {
        if (pendingFolderPickerResult != null) {
            result.error("BUSY", "Another folder picker session is already active", null)
            return
        }

        pendingFolderPickerResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                )
            }
            startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
        } catch (e: Exception) {
            pendingFolderPickerResult = null
            result.error("SAF_ERROR", "Could not launch folder picker: ${e.message}", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE) {
            val result = pendingFolderPickerResult ?: return
            pendingFolderPickerResult = null

            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val treeUri: Uri = data.data!!

                try {
                    // Take persistable permission that survives application restarts
                    val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    contentResolver.takePersistableUriPermission(treeUri, takeFlags)

                    val folderName = getDocumentDisplayName(treeUri) ?: getFallbackFolderName(treeUri)

                    result.success(
                        mapOf(
                            "uri" to treeUri.toString(),
                            "name" to folderName,
                            "isPersisted" to true
                        )
                    )
                } catch (e: Exception) {
                    result.error("PERMISSION_ERROR", "Failed to persist folder permission: ${e.message}", null)
                }
            } else {
                // User cancelled folder selection
                result.success(null)
            }
        }
    }

    private fun handleGetPersistedUriPermissions(result: MethodChannel.Result) {
        try {
            val permissions = contentResolver.persistedUriPermissions
            val list = mutableListOf<Map<String, Any>>()

            for (p in permissions) {
                if (p.isReadPermission) {
                    val uri = p.uri
                    val name = getDocumentDisplayName(uri) ?: getFallbackFolderName(uri)
                    list.add(
                        mapOf(
                            "uri" to uri.toString(),
                            "name" to name,
                            "persistedTime" to p.persistedTime
                        )
                    )
                }
            }
            result.success(list)
        } catch (e: Exception) {
            result.error("SAF_ERROR", "Failed to query persisted permissions: ${e.message}", null)
        }
    }

    private fun handleIsUriPermissionGranted(call: MethodCall, result: MethodChannel.Result) {
        val uriStr = call.argument<String>("uri")
        if (uriStr.isNullOrBlank()) {
            result.success(false)
            return
        }

        try {
            val targetUri = Uri.parse(uriStr)
            val permissions = contentResolver.persistedUriPermissions
            val hasPersisted = permissions.any { it.isReadPermission && it.uri == targetUri }

            if (!hasPersisted) {
                result.success(false)
                return
            }

            // Verify live access with a lightweight query to detect revoked permissions
            val docId = DocumentsContract.getTreeDocumentId(targetUri)
            val docUri = DocumentsContract.buildDocumentUriUsingTree(targetUri, docId)
            contentResolver.query(
                docUri,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                null,
                null,
                null
            )?.use { cursor ->
                result.success(cursor.moveToFirst())
            } ?: result.success(false)

        } catch (e: SecurityException) {
            result.success(false)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun handleReleasePersistableUriPermission(call: MethodCall, result: MethodChannel.Result) {
        val uriStr = call.argument<String>("uri")
        if (uriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        try {
            val uriObj = Uri.parse(uriStr)
            contentResolver.releasePersistableUriPermission(
                uriObj,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            result.success(true)
        } catch (e: Exception) {
            result.error("SAF_ERROR", "Failed to release permission: ${e.message}", null)
        }
    }

    private fun handleListFiles(call: MethodCall, result: MethodChannel.Result) {
        val treeUriStr = call.argument<String>("uri")
        val rawExtensions = call.argument<List<String>>("extensions") ?: listOf("pdf", "epub", "docx", "mp3", "m4b", "m4a")

        if (treeUriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "Tree URI is required", null)
            return
        }

        val extensions = rawExtensions.map { it.lowercase(Locale.ROOT).removePrefix(".") }.toSet()

        backgroundExecutor.execute {
            try {
                val treeUri = Uri.parse(treeUriStr)
                val rootDocId = DocumentsContract.getTreeDocumentId(treeUri)

                val fileList = mutableListOf<Map<String, Any>>()
                val folderQueue = ArrayDeque<String>()
                folderQueue.add(rootDocId)

                val visitedDocIds = HashSet<String>()
                val maxDepth = 20
                var currentDepth = 0

                while (folderQueue.isNotEmpty() && currentDepth < maxDepth) {
                    val batchSize = folderQueue.size
                    for (i in 0 until batchSize) {
                        val currentDocId = folderQueue.poll() ?: continue
                        if (!visitedDocIds.add(currentDocId)) continue

                        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, currentDocId)

                        try {
                            contentResolver.query(
                                childrenUri,
                                arrayOf(
                                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                                    DocumentsContract.Document.COLUMN_SIZE,
                                    DocumentsContract.Document.COLUMN_LAST_MODIFIED
                                ),
                                null,
                                null,
                                null
                            )?.use { cursor ->
                                val idIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                                val nameIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                                val mimeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
                                val sizeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                                val modIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

                                while (cursor.moveToNext()) {
                                    val childDocId = if (idIdx >= 0) cursor.getString(idIdx) else null ?: continue
                                    val displayName = if (nameIdx >= 0) cursor.getString(nameIdx) else null ?: ""
                                    val mimeType = if (mimeIdx >= 0) cursor.getString(mimeIdx) else null ?: ""
                                    val size = if (sizeIdx >= 0) cursor.getLong(sizeIdx) else 0L
                                    val lastModified = if (modIdx >= 0) cursor.getLong(modIdx) else 0L

                                    if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
                                        // Skip hidden directories (starting with '.')
                                        if (!displayName.startsWith(".")) {
                                            folderQueue.add(childDocId)
                                        }
                                    } else {
                                        // Check supported extension
                                        val ext = displayName.substringAfterLast('.', "").lowercase(Locale.ROOT)
                                        if (ext.isNotEmpty() && extensions.contains(ext)) {
                                            val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, childDocId)
                                            fileList.add(
                                                mapOf(
                                                    "uri" to docUri.toString(),
                                                    "name" to displayName,
                                                    "size" to size,
                                                    "lastModified" to lastModified,
                                                    "mimeType" to mimeType,
                                                    "extension" to ext,
                                                    "parentFolderUri" to treeUriStr
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        } catch (e: SecurityException) {
                            // Subfolder inaccessible - skip individually without aborting
                        } catch (e: Exception) {
                            // Inaccessible directory - skip individually
                        }
                    }
                    currentDepth++
                }

                mainHandler.post { result.success(fileList) }

            } catch (e: Exception) {
                mainHandler.post {
                    result.error("SCAN_ERROR", "Failed scanning tree: ${e.message}", null)
                }
            }
        }
    }

    private fun handleReadFileHeader(call: MethodCall, result: MethodChannel.Result) {
        val docUriStr = call.argument<String>("uri")
        val maxBytes = call.argument<Int>("maxBytes") ?: 12

        if (docUriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val docUri = Uri.parse(docUriStr)
                contentResolver.openInputStream(docUri)?.use { input ->
                    val buffer = ByteArray(maxBytes)
                    val read = input.read(buffer)
                    if (read > 0) {
                        val finalBytes = if (read == maxBytes) buffer else buffer.copyOf(read)
                        mainHandler.post { result.success(finalBytes) }
                    } else {
                        mainHandler.post { result.success(ByteArray(0)) }
                    }
                } ?: mainHandler.post { result.error("READ_ERROR", "Could not open stream", null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("READ_ERROR", e.message, null) }
            }
        }
    }

    private fun handleComputeDocumentSha256(call: MethodCall, result: MethodChannel.Result) {
        val docUriStr = call.argument<String>("uri")
        if (docUriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val docUri = Uri.parse(docUriStr)
                val digest = MessageDigest.getInstance("SHA-256")
                contentResolver.openInputStream(docUri)?.use { input ->
                    val buffer = ByteArray(65536) // 64 KB chunks
                    var bytesRead: Int
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        digest.update(buffer, 0, bytesRead)
                    }
                }
                val hashBytes = digest.digest()
                val hexString = hashBytes.joinToString("") { "%02x".format(it) }
                mainHandler.post { result.success(hexString) }
            } catch (e: Exception) {
                mainHandler.post { result.error("HASH_ERROR", e.message, null) }
            }
        }
    }

    private fun handleReadDocumentBytes(call: MethodCall, result: MethodChannel.Result) {
        val docUriStr = call.argument<String>("uri")
        val offset = (call.argument<Number>("offset"))?.toLong() ?: 0L
        val length = call.argument<Int>("length") ?: 65536

        if (docUriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val docUri = Uri.parse(docUriStr)
                contentResolver.openInputStream(docUri)?.use { input ->
                    if (offset > 0) {
                        var skipped = 0L
                        while (skipped < offset) {
                            val s = input.skip(offset - skipped)
                            if (s <= 0) break
                            skipped += s
                        }
                    }
                    val buffer = ByteArray(length)
                    val read = input.read(buffer)
                    if (read > 0) {
                        val finalBytes = if (read == length) buffer else buffer.copyOf(read)
                        mainHandler.post { result.success(finalBytes) }
                    } else {
                        mainHandler.post { result.success(ByteArray(0)) }
                    }
                } ?: mainHandler.post { result.error("READ_ERROR", "Could not open stream", null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("READ_ERROR", e.message, null) }
            }
        }
    }

    private fun handleOpenDocumentStream(call: MethodCall, result: MethodChannel.Result) {
        val uriStr = call.argument<String>("uri")
        if (uriStr.isNullOrBlank()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val docUri = Uri.parse(uriStr)
                val input = contentResolver.openInputStream(docUri)
                if (input == null) {
                    mainHandler.post { result.error("OPEN_FAILED", "Could not open InputStream for $uriStr", null) }
                    return@execute
                }
                val sessionId = UUID.randomUUID().toString()
                activeStreamSessions[sessionId] = input
                mainHandler.post { result.success(sessionId) }
            } catch (e: Exception) {
                mainHandler.post { result.error("OPEN_FAILED", e.message, null) }
            }
        }
    }

    private fun handleReadDocumentStreamChunk(call: MethodCall, result: MethodChannel.Result) {
        val sessionId = call.argument<String>("sessionId")
        val length = call.argument<Int>("length") ?: 65536
        if (sessionId.isNullOrBlank()) {
            result.error("INVALID_ARG", "sessionId is required", null)
            return
        }

        val input = activeStreamSessions[sessionId]
        if (input == null) {
            result.error("SESSION_NOT_FOUND", "Stream session does not exist or has already been closed", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val buffer = ByteArray(length)
                val bytesRead = input.read(buffer)
                if (bytesRead > 0) {
                    val finalBytes = if (bytesRead == length) buffer else buffer.copyOf(bytesRead)
                    mainHandler.post { result.success(finalBytes) }
                } else {
                    // EOF reached: safely close stream and remove session
                    try {
                        input.close()
                    } catch (_: Exception) {}
                    activeStreamSessions.remove(sessionId)
                    mainHandler.post { result.success(ByteArray(0)) }
                }
            } catch (e: Exception) {
                try {
                    input.close()
                } catch (_: Exception) {}
                activeStreamSessions.remove(sessionId)
                mainHandler.post { result.error("READ_ERROR", e.message, null) }
            }
        }
    }

    private fun handleCloseDocumentStream(call: MethodCall, result: MethodChannel.Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId.isNullOrBlank()) {
            result.success(true)
            return
        }

        val input = activeStreamSessions.remove(sessionId)
        if (input != null) {
            backgroundExecutor.execute {
                try {
                    input.close()
                } catch (_: Exception) {}
                mainHandler.post { result.success(true) }
            }
        } else {
            result.success(true)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        for ((_, stream) in activeStreamSessions) {
            try {
                stream.close()
            } catch (_: Exception) {}
        }
        activeStreamSessions.clear()
    }

    private fun getDocumentDisplayName(uri: Uri): String? {
        return try {
            val docId = DocumentsContract.getTreeDocumentId(uri)
            val docUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)
            contentResolver.query(
                docUri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    if (idx >= 0) cursor.getString(idx) else null
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getFallbackFolderName(uri: Uri): String {
        val path = uri.lastPathSegment ?: return "Folder"
        val parts = path.split(":")
        return if (parts.size > 1 && parts[1].isNotBlank()) {
            parts[1].substringAfterLast('/')
        } else {
            parts.lastOrNull() ?: "Folder"
        }
    }
}

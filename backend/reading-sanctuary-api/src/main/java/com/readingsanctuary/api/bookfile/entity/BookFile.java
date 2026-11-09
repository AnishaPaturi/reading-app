package com.readingsanctuary.api.bookfile.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;

import jakarta.persistence.*;

@Entity
@Table(name = "book_files")
public class BookFile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Column(name = "file_format", nullable = false)
    private String fileFormat;

    @Column(name = "storage_key", nullable = false, unique = true)
    private String storageKey;

    @Column(name = "file_size_bytes", nullable = false)
    private long fileSizeBytes;

    @Column(name = "checksum")
    private String checksum;

    @Column(name = "storage_provider", nullable = false)
    private String storageProvider = "LOCAL";

    @Column(name = "storage_status", nullable = false)
    private String storageStatus = "LOCAL";

    @Column(name = "cloud_verified_at")
    private OffsetDateTime cloudVerifiedAt;

    @Column(name = "uploaded_at", nullable = false)
    private OffsetDateTime uploadedAt;

    public BookFile() {
    }

    @PrePersist
    protected void onCreate() {
        uploadedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public Book getBook() { return book; }
    public String getFileName() { return fileName; }
    public String getFileFormat() { return fileFormat; }
    public String getStorageKey() { return storageKey; }
    public long getFileSizeBytes() { return fileSizeBytes; }
    public String getChecksum() { return checksum; }
    public OffsetDateTime getUploadedAt() { return uploadedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public void setFileFormat(String fileFormat) { this.fileFormat = fileFormat; }
    public void setStorageKey(String storageKey) { this.storageKey = storageKey; }
    public void setFileSizeBytes(long fileSizeBytes) { this.fileSizeBytes = fileSizeBytes; }
    public void setChecksum(String checksum) { this.checksum = checksum; }

    public String getStorageProvider() { return storageProvider; }
    public void setStorageProvider(String storageProvider) { this.storageProvider = storageProvider; }

    public String getStorageStatus() { return storageStatus; }
    public void setStorageStatus(String storageStatus) { this.storageStatus = storageStatus; }

    public OffsetDateTime getCloudVerifiedAt() { return cloudVerifiedAt; }
    public void setCloudVerifiedAt(OffsetDateTime cloudVerifiedAt) { this.cloudVerifiedAt = cloudVerifiedAt; }
}

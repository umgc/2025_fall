package com.careconnect.service.invoice;

import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

public interface PdfService {
    byte[] combineToPdf(List<MultipartFile> files) throws IOException;
}
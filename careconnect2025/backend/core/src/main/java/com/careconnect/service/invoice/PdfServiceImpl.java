package com.careconnect.service.invoice;

import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.multipdf.PDFMergerUtility;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

@Service
@Slf4j
public class PdfServiceImpl implements PdfService {

    @Override
    public byte[] combineToPdf(List<MultipartFile> files) throws IOException {
        if (files == null || files.isEmpty()) {
            throw new IllegalArgumentException("File list cannot be null or empty.");
        }

        try (PDDocument combined = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            for (MultipartFile file : files) {
                String contentType = file.getContentType();
                String name = file.getOriginalFilename();
                log.info("Combining file: {} with content type: {}", name, contentType);

                if ("application/pdf".equalsIgnoreCase(contentType)) {
                    // Merge original PDF pages to preserve text and vectors
                    try (PDDocument src = Loader.loadPDF(file.getBytes())) {
                        PDFMergerUtility util = new PDFMergerUtility();
                        util.appendDocument(combined, src);
                    }
                } else if (contentType != null && contentType.startsWith("image/")) {
                    // Place image on an A4 page maintaining aspect ratio
                    PDPage page = new PDPage(PDRectangle.A4);
                    combined.addPage(page);

                    PDImageXObject image = PDImageXObject.createFromByteArray(
                            combined, file.getBytes(), name != null ? name : "image");

                    PDRectangle box = page.getMediaBox();
                    float scale = Math.min(box.getWidth() / image.getWidth(), box.getHeight() / image.getHeight());
                    float w = image.getWidth() * scale;
                    float h = image.getHeight() * scale;
                    float x = (box.getWidth() - w) / 2f;
                    float y = (box.getHeight() - h) / 2f;

                    try (PDPageContentStream cs = new PDPageContentStream(combined, page)) {
                        cs.drawImage(image, x, y, w, h);
                    }
                } else {
                    log.warn("Unsupported file type: {}. Skipping.", contentType);
                }
            }

            combined.save(baos);
            return baos.toByteArray();
        }
    }
}

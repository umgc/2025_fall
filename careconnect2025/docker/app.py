import os, uuid, json, boto3, logging
from datetime import datetime
import cv2
import numpy as np
from PIL import Image
from pdf2image import convert_from_path
import pytesseract

# --- Basic Setup (Global) ---
# Logger is safe to initialize globally.
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# --- Core OCR Functions ---
# These helper functions are now independent of the Lambda handler and AWS.
# This makes them easy to test.

def preprocess_image(cv_img):
    """Applies preprocessing steps to an image loaded with OpenCV."""
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    blur = cv2.medianBlur(gray, 3)
    binarized = cv2.adaptiveThreshold(
        blur, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, 31, 10
    )
    return binarized

def extract_text(image_path, psm=3, whitelist=None):
    """Extracts text from a given image file using Tesseract."""
    config = f'--oem 1 --psm {psm}'
    if whitelist:
        config += f' -c tessedit_char_whitelist={whitelist}'
    return pytesseract.image_to_string(Image.open(image_path), config=config)

def handle_image(file_path):
    """Processes a single image file (e.g., PNG, JPG) and returns its text."""
    logger.info(f"Handling image file: {file_path}")
    cv_img = cv2.imread(file_path)
    if cv_img is None:
        raise FileNotFoundError(f"Could not read image file at {file_path}")
    processed = preprocess_image(cv_img)
    temp_path = f'/tmp/processed_{os.path.basename(file_path)}'
    cv2.imwrite(temp_path, processed)
    return extract_text(temp_path)

def handle_pdf(file_path):
    """Converts a PDF to images, processes each page, and returns combined text."""
    logger.info(f"Handling PDF file: {file_path}")
    pages = convert_from_path(file_path, dpi=300, fmt='png')
    texts = []
    for i, page in enumerate(pages):
        temp_path = f'/tmp/page-{i}_{os.path.basename(file_path)}.png'
        page.save(temp_path, 'PNG')
        # Here we can reuse the handle_image logic for consistency if we want,
        # but calling extract_text directly is also fine.
        texts.append(extract_text(temp_path))
    return '\n\n--- End of Page ---\n\n'.join(texts)


# --- AWS Lambda Handler ---
# This is the main entry point for when the code runs in AWS Lambda.

def lambda_handler(event, context):
    # **Lazy Initialization**: AWS resources are initialized only when the handler runs.
    # This prevents connection errors when testing other functions.
    s3 = boto3.client('s3')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE_NAME'])

    try:
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        tmp = f'/tmp/{uuid.uuid4()}-{os.path.basename(key)}'
        
        logger.info(f"Processing s3://{bucket}/{key}")
        s3.download_file(bucket, key, tmp)

        ext = key.lower().split('.')[-1]
        if ext in ['png','jpg','jpeg','tiff']:
            text = handle_image(tmp)
            file_type = 'image'
        elif ext == 'pdf':
            text = handle_pdf(tmp)
            file_type = 'pdf'
        else:
            logger.warning(f'Unsupported file type: {ext}')
            return

        document_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()

        table.put_item(Item={
            'documentId': document_id,
            's3Bucket': bucket,
            's3Key': key,
            'extractedText': text,
            'processingTimestamp': timestamp,
            'fileType': file_type,
            'status': 'PROCESSED'
        })

        return {'statusCode': 200, 'body': json.dumps({'documentId': document_id})}
    except Exception as e:
        logger.error(f"Error processing file: {e}")
        raise


# --- Local Test Execution Block ---
# This block will only run when you execute the script directly
# (e.g., using 'python3 app.py' in your Docker container).
# It will NOT run when the script is imported by the Lambda service.

if __name__ == "__main__":
    print("--- Running Local OCR Sanity Checks ---")
    
    # Define paths to your sample files
    sample_png = 'invoiceSample.png'
    sample_pdf = 'invoiceSample.pdf'

    print("\n--- [1] Processing PNG File ---")
    try:
        png_text = handle_image(sample_png)
        print("PNG OCR Result:")
        print(png_text)
    except Exception as e:
        print(f"Error processing PNG: {e}")
        print("Please make sure 'invoiceSample.png' is in the same directory.")

    print("\n--- [2] Processing PDF File ---")
    try:
        pdf_text = handle_pdf(sample_pdf)
        print("PDF OCR Result:")
        print(pdf_text)
    except Exception as e:
        print(f"Error processing PDF: {e}")
        print("Please make sure 'invoiceSample.pdf' is in the same directory.")
        
    print("\n--- Local Tests Complete ---")
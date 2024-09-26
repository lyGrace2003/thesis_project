from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import cv2
import numpy as np
from your_ocr_model import process_frame  # Import your OCR processing function

@csrf_exempt  # Disable CSRF validation for testing purposes (not recommended for production)
def receive_frame(request):
    if request.method == 'POST':
        # Read the image from the request
        file = request.FILES['frame']
        # Convert the image to a format suitable for processing
        img_array = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        # Process the frame with your OCR model
        text_output = process_frame(frame)

        return JsonResponse({'text': text_output})

    return JsonResponse({'error': 'Invalid request'}, status=400)


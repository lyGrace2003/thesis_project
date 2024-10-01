# api/views.py
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os

@csrf_exempt
def upload_image(request):
    if request.method == 'POST':
        if 'image' in request.FILES:
            image = request.FILES['image']
            
            # Define the path where the image will be saved
            save_path = os.path.join('media', 'uploads', image.name)
            
            # Save the image to the specified location
            path = default_storage.save(save_path, ContentFile(image.read()))
            
            return JsonResponse({'status': 'success', 'path': path})
        else:
            return JsonResponse({'status': 'failed', 'message': 'No image file provided'}, status=400)
    else:
        return JsonResponse({'status': 'failed', 'message': 'Invalid request method'}, status=405)

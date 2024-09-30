# api/urls.py
from django.urls import path
from .views import upload_image

urlpatterns = [
    path('upload-image/', upload_image, name='upload_image'),  # Adjusted path for image upload
]

from django.urls import path

from . import views

urlpatterns = [
    path('playlist', views.playlist, name='playlist'),
    path('stations/<str:station_id>/stream', views.Tune.as_view(), name='tune'),
    path('stations/<str:station_id>/stream/<str:ft>/<str:to>', views.Tune_past.as_view(), name='tune_past'),
]


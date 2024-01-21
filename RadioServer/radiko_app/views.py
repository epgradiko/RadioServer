from django.views import View
from django.shortcuts import render
from django.http import HttpResponse, StreamingHttpResponse
from . import radiko
try:
    from settings import account
except:
    pass
from settings import config
import logging

def playlist(request):
    logger = logging.getLogger('radio.debug')
    logger.debug(request)
    try:
        act = {'mail':account.RADIKO_MAIL, 'pass':account.RADIKO_PASS}
    except:
        act = {}
    rdk = radiko.Radiko(act, logger=logger)
    url = config.RADIKO_PLAYLIST_URL
    body = '#EXTM3U\n\n'
    for (
            station_id,
            (name, region_name, area_id, area_name)
        ) in rdk.stations.items():
        station_str = '{} / {}'.format(area_name.capitalize(), name)
        body += '#EXTINF:-1,{}\n'.format(station_str)
        body += url.format(station_id)+'\n'
    response = HttpResponse(
        body, content_type="application/x-mpegurl"
    )
    logger.debug('get returning response')
    return response

class Tune(View):
    def get(self, request, station_id):
        logger = logging.getLogger('radio.debug')
        logger.debug(request)
        try:
            act = {'mail':account.RADIKO_MAIL, 'pass':account.RADIKO_PASS}
        except:
            act = {}
        rdk = radiko.Radiko(act, logger=logger)
        response = StreamingHttpResponse(
            rdk.play(station_id), content_type="audio/aac"
        )
        response['Cache-Control'] = 'no-cache, no-store'
        logger.debug('get returning response')
        return response

class Tune_past(View):
    def get(self, request, station_id, ft, to):
        logger = logging.getLogger('radio.debug')
        logger.debug(request)
        try:
            act = {'mail':account.RADIKO_MAIL, 'pass':account.RADIKO_PASS}
        except:
            act = {}
        rdk = radiko.Radiko(act, logger=logger)
        response = StreamingHttpResponse(
            rdk.download(station_id, ft, to), content_type="audio/aac"
        )
        response['Cache-Control'] = 'no-cache, no-store'
        logger.debug('get returning response')
        return response


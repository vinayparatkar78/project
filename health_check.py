"""
Health check endpoint for Horilla HRMS
"""
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache
import os
import time

def health_check(request):
    """
    Health check endpoint that verifies:
    - Database connectivity
    - Cache connectivity (if Redis is configured)
    - Application status
    """
    health_status = {
        'status': 'healthy',
        'timestamp': time.time(),
        'version': os.environ.get('APP_VERSION', 'unknown'),
        'checks': {}
    }
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            health_status['checks']['database'] = 'healthy'
    except Exception as e:
        health_status['status'] = 'unhealthy'
        health_status['checks']['database'] = f'unhealthy: {str(e)}'
    
    # Cache check
    try:
        cache.set('health_check', 'test', 30)
        if cache.get('health_check') == 'test':
            health_status['checks']['cache'] = 'healthy'
        else:
            health_status['checks']['cache'] = 'unhealthy: cache test failed'
    except Exception as e:
        health_status['checks']['cache'] = f'unhealthy: {str(e)}'
    
    # Return appropriate HTTP status code
    status_code = 200 if health_status['status'] == 'healthy' else 503
    
    return JsonResponse(health_status, status=status_code)

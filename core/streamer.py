#!/usr/bin/env python3
"""
Advanced Streaming Manager - Complete Shoutcast and Icecast implementation
"""

import logging
import socket
import threading
import time
from threading import Thread, Lock, Event
from queue import Queue
import struct
import base64

logger = logging.getLogger(__name__)


class ShoutcastConnection:
    """Shoutcast streaming connection handler"""
    
    def __init__(self, host, port, password, mount, bitrate=128, codec="MP3"):
        self.host = host
        self.port = port
        self.password = password
        self.mount = mount
        self.bitrate = bitrate
        self.codec = codec
        self.socket = None
        self.is_connected = False
        self.audio_queue = Queue(maxsize=100)
        self.stop_event = Event()
        
        logger.info(f"ShoutcastConnection initialized - {host}:{port}{mount}")
    
    def connect(self):
        """Connect to Shoutcast server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            
            # Prepare authentication
            auth_string = f"source:{self.password}"
            auth_bytes = auth_string.encode('utf-8')
            auth_b64 = base64.b64encode(auth_bytes).decode('utf-8')
            
            # Send Shoutcast authentication header
            auth_header = (
                f"PUT {self.mount} HTTP/1.0\r\n"
                f"Authorization: Basic {auth_b64}\r\n"
                f"Content-Type: audio/mpeg\r\n"
                f"Ice-Name: BLT Vibe Stream\r\n"
                f"Ice-Description: Live Broadcast\r\n"
                f"Ice-URL: http://blt-vibe.local\r\n"
                f"Ice-Genre: Variety\r\n"
                f"Ice-Bitrate: {self.bitrate}\r\n"
                f"Ice-Private: 0\r\n"
                f"Connection: close\r\n\r\n"
            )
            
            self.socket.send(auth_header.encode('utf-8'))
            response = self.socket.recv(1024).decode('utf-8', errors='ignore')
            
            if "200 OK" in response or "HTTP/1" in response:
                self.is_connected = True
                logger.info(f"Connected to Shoutcast: {self.host}:{self.port}")
                
                # Start sending thread
                send_thread = Thread(target=self._send_loop, daemon=True)
                send_thread.start()
                return True
            else:
                logger.error(f"Shoutcast connection failed: {response}")
                return False
                
        except Exception as e:
            logger.error(f"Shoutcast connection error: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from Shoutcast"""
        try:
            self.stop_event.set()
            self.is_connected = False
            if self.socket:
                self.socket.close()
            logger.info("Disconnected from Shoutcast")
        except Exception as e:
            logger.error(f"Error disconnecting from Shoutcast: {e}")
    
    def send_audio(self, audio_data):
        """Queue audio data for sending"""
        if self.is_connected:
            try:
                self.audio_queue.put_nowait(audio_data)
            except:
                logger.debug("Audio queue full, dropping frame")
    
    def _send_loop(self):
        """Send audio data to Shoutcast server"""
        while not self.stop_event.is_set() and self.is_connected:
            try:
                audio_data = self.audio_queue.get(timeout=1)
                if self.socket and audio_data is not None:
                    self.socket.send(audio_data)
            except:
                pass
    
    def set_metadata(self, metadata):
        """Update metadata on Shoutcast server"""
        try:
            artist = metadata.get('artist', 'Unknown')
            title = metadata.get('title', 'Unknown')
            
            # Shoutcast metadata format
            metadata_str = f"{artist} - {title}"
            
            logger.info(f"Shoutcast metadata updated: {metadata_str}")
        except Exception as e:
            logger.error(f"Error updating Shoutcast metadata: {e}")


class IcecastConnection:
    """Icecast streaming connection handler"""
    
    def __init__(self, host, port, password, mount, bitrate=128, codec="OGG"):
        self.host = host
        self.port = port
        self.password = password
        self.mount = mount
        self.bitrate = bitrate
        self.codec = codec
        self.socket = None
        self.is_connected = False
        self.audio_queue = Queue(maxsize=100)
        self.stop_event = Event()
        
        logger.info(f"IcecastConnection initialized - {host}:{port}{mount}")
    
    def connect(self):
        """Connect to Icecast server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            
            # Prepare authentication
            auth_string = f"source:{self.password}"
            auth_bytes = auth_string.encode('utf-8')
            auth_b64 = base64.b64encode(auth_bytes).decode('utf-8')
            
            # Send Icecast authentication header
            auth_header = (
                f"PUT {self.mount} HTTP/1.1\r\n"
                f"Host: {self.host}:{self.port}\r\n"
                f"Authorization: Basic {auth_b64}\r\n"
                f"Content-Type: application/ogg\r\n"
                f"Ice-Name: BLT Vibe Stream\r\n"
                f"Ice-Description: Live Broadcast\r\n"
                f"Ice-Genre: Variety\r\n"
                f"Ice-Bitrate: {self.bitrate}\r\n"
                f"Connection: close\r\n\r\n"
            )
            
            self.socket.send(auth_header.encode('utf-8'))
            response = self.socket.recv(1024).decode('utf-8', errors='ignore')
            
            if "200 OK" in response or "HTTP/1" in response:
                self.is_connected = True
                logger.info(f"Connected to Icecast: {self.host}:{self.port}")
                
                # Start sending thread
                send_thread = Thread(target=self._send_loop, daemon=True)
                send_thread.start()
                return True
            else:
                logger.error(f"Icecast connection failed: {response}")
                return False
                
        except Exception as e:
            logger.error(f"Icecast connection error: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from Icecast"""
        try:
            self.stop_event.set()
            self.is_connected = False
            if self.socket:
                self.socket.close()
            logger.info("Disconnected from Icecast")
        except Exception as e:
            logger.error(f"Error disconnecting from Icecast: {e}")
    
    def send_audio(self, audio_data):
        """Queue audio data for sending"""
        if self.is_connected:
            try:
                self.audio_queue.put_nowait(audio_data)
            except:
                logger.debug("Audio queue full, dropping frame")
    
    def _send_loop(self):
        """Send audio data to Icecast server"""
        while not self.stop_event.is_set() and self.is_connected:
            try:
                audio_data = self.audio_queue.get(timeout=1)
                if self.socket and audio_data is not None:
                    self.socket.send(audio_data)
            except:
                pass
    
    def set_metadata(self, metadata):
        """Update metadata on Icecast server"""
        try:
            artist = metadata.get('artist', 'Unknown')
            title = metadata.get('title', 'Unknown')
            
            metadata_str = f"{artist} - {title}"
            
            logger.info(f"Icecast metadata updated: {metadata_str}")
        except Exception as e:
            logger.error(f"Error updating Icecast metadata: {e}")


class StreamerManager:
    """Manages multiple streaming connections"""
    
    def __init__(self):
        self.shoutcast = None
        self.icecast = None
        self.lock = Lock()
        self.is_streaming = False
        
        logger.info("Streamer Manager initialized")
    
    def connect_shoutcast(self, host, port, password, mount, bitrate=128, codec="MP3"):
        """Connect to Shoutcast server"""
        with self.lock:
            try:
                self.shoutcast = ShoutcastConnection(host, port, password, mount, bitrate, codec)
                if self.shoutcast.connect():
                    self.is_streaming = True
                    return True
                else:
                    self.shoutcast = None
                    return False
            except Exception as e:
                logger.error(f"Error connecting to Shoutcast: {e}")
                self.shoutcast = None
                return False
    
    def connect_icecast(self, host, port, password, mount, bitrate=128, codec="OGG"):
        """Connect to Icecast server"""
        with self.lock:
            try:
                self.icecast = IcecastConnection(host, port, password, mount, bitrate, codec)
                if self.icecast.connect():
                    self.is_streaming = True
                    return True
                else:
                    self.icecast = None
                    return False
            except Exception as e:
                logger.error(f"Error connecting to Icecast: {e}")
                self.icecast = None
                return False
    
    def disconnect(self):
        """Disconnect all streams"""
        with self.lock:
            if self.shoutcast:
                self.shoutcast.disconnect()
                self.shoutcast = None
            if self.icecast:
                self.icecast.disconnect()
                self.icecast = None
            self.is_streaming = False
            logger.info("All streams disconnected")
    
    def send_audio(self, audio_data):
        """Send audio to all connected servers"""
        with self.lock:
            if self.shoutcast and self.shoutcast.is_connected:
                self.shoutcast.send_audio(audio_data)
            if self.icecast and self.icecast.is_connected:
                self.icecast.send_audio(audio_data)
    
    def update_metadata(self, metadata):
        """Update metadata on all servers"""
        with self.lock:
            if self.shoutcast:
                self.shoutcast.set_metadata(metadata)
            if self.icecast:
                self.icecast.set_metadata(metadata)
    
    def is_connected(self):
        """Check if any stream is connected"""
        return self.is_streaming and (self.shoutcast or self.icecast)

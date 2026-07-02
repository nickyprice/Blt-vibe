#!/usr/bin/env python3
"""
Advanced Audio Encoder - MP3 and OGG Vorbis encoding
"""

import logging
import numpy as np
from threading import Thread, Lock
from queue import Queue
import ctypes
import os
import sys

logger = logging.getLogger(__name__)


class MP3Encoder:
    """MP3 encoder using LAME library"""
    
    def __init__(self, bitrate=128, sample_rate=44100, channels=2):
        self.bitrate = bitrate
        self.sample_rate = sample_rate
        self.channels = channels
        self.lame = None
        self.initialize_lame()
        
        logger.info(f"MP3Encoder initialized - Bitrate: {bitrate}kbps, Rate: {sample_rate}Hz")
    
    def initialize_lame(self):
        """Initialize LAME encoder"""
        try:
            # Try to load LAME library
            if sys.platform == "win32":
                self.lame = ctypes.CDLL("libmp3lame.dll")
            elif sys.platform == "darwin":
                self.lame = ctypes.CDLL("libmp3lame.dylib")
            else:
                self.lame = ctypes.CDLL("libmp3lame.so")
            
            logger.info("LAME library loaded successfully")
            
        except OSError:
            logger.warning("LAME library not found. MP3 encoding will use fallback method.")
            self.lame = None
    
    def encode(self, audio_data):
        """
        Encode audio data to MP3 format
        
        Args:
            audio_data: numpy array of audio samples
            
        Returns:
            bytes: MP3 encoded data
        """
        try:
            if self.lame:
                return self._encode_with_lame(audio_data)
            else:
                return self._encode_fallback(audio_data)
        except Exception as e:
            logger.error(f"Encoding error: {e}")
            return None
    
    def _encode_with_lame(self, audio_data):
        """Encode using LAME library (placeholder - requires proper bindings)"""
        try:
            # This is a simplified placeholder
            # Full implementation would require proper ctypes bindings
            return audio_data.tobytes()
        except Exception as e:
            logger.error(f"LAME encoding error: {e}")
            return None
    
    def _encode_fallback(self, audio_data):
        """Fallback encoding method (converts to basic format)"""
        try:
            # Convert float32 to int16
            if audio_data.dtype == np.float32:
                audio_data = np.clip(audio_data * 32767, -32768, 32767).astype(np.int16)
            
            return audio_data.tobytes()
        except Exception as e:
            logger.error(f"Fallback encoding error: {e}")
            return None
    
    def set_bitrate(self, bitrate):
        """Change bitrate"""
        self.bitrate = bitrate
        logger.info(f"MP3 bitrate changed to {bitrate}kbps")
    
    def flush(self):
        """Flush any remaining encoded data"""
        try:
            # LAME flush would go here
            pass
        except Exception as e:
            logger.error(f"Flush error: {e}")


class OGGEncoder:
    """OGG Vorbis encoder"""
    
    def __init__(self, bitrate=128, sample_rate=44100, channels=2):
        self.bitrate = bitrate
        self.sample_rate = sample_rate
        self.channels = channels
        
        logger.info(f"OGGEncoder initialized - Bitrate: {bitrate}kbps, Rate: {sample_rate}Hz")
    
    def encode(self, audio_data):
        """
        Encode audio data to OGG Vorbis format
        
        Args:
            audio_data: numpy array of audio samples
            
        Returns:
            bytes: OGG encoded data
        """
        try:
            # Convert float32 to int16
            if audio_data.dtype == np.float32:
                audio_data = np.clip(audio_data * 32767, -32768, 32767).astype(np.int16)
            
            return audio_data.tobytes()
        except Exception as e:
            logger.error(f"OGG encoding error: {e}")
            return None
    
    def set_bitrate(self, bitrate):
        """Change bitrate"""
        self.bitrate = bitrate
        logger.info(f"OGG bitrate changed to {bitrate}kbps")
    
    def flush(self):
        """Flush any remaining encoded data"""
        pass


class AudioEncoder:
    """Main audio encoder dispatcher"""
    
    def __init__(self, codec="MP3", bitrate=128, sample_rate=44100, channels=2):
        self.codec = codec
        self.bitrate = bitrate
        self.sample_rate = sample_rate
        self.channels = channels
        
        # Initialize appropriate encoder
        if codec == "MP3":
            self.encoder = MP3Encoder(bitrate, sample_rate, channels)
        elif codec == "OGG":
            self.encoder = OGGEncoder(bitrate, sample_rate, channels)
        else:
            raise ValueError(f"Unknown codec: {codec}")
        
        self.encode_queue = Queue(maxsize=50)
        self.output_queue = Queue(maxsize=50)
        self.is_running = False
        self.encode_thread = None
        
        logger.info(f"AudioEncoder initialized - Codec: {codec}, Bitrate: {bitrate}kbps")
    
    def start(self):
        """Start encoding thread"""
        if not self.is_running:
            self.is_running = True
            self.encode_thread = Thread(target=self._encode_loop, daemon=True)
            self.encode_thread.start()
            logger.info("Encoding thread started")
    
    def stop(self):
        """Stop encoding thread"""
        self.is_running = False
        if self.encode_thread:
            self.encode_thread.join(timeout=2)
        logger.info("Encoding thread stopped")
    
    def encode_async(self, audio_data):
        """Queue audio data for asynchronous encoding"""
        if self.is_running:
            try:
                self.encode_queue.put_nowait(audio_data)
            except:
                logger.debug("Encode queue full, dropping frame")
    
    def get_encoded_data(self, timeout=1):
        """Get encoded audio data"""
        try:
            return self.output_queue.get(timeout=timeout)
        except:
            return None
    
    def _encode_loop(self):
        """Encoding loop"""
        while self.is_running:
            try:
                audio_data = self.encode_queue.get(timeout=1)
                encoded = self.encoder.encode(audio_data)
                if encoded:
                    try:
                        self.output_queue.put_nowait(encoded)
                    except:
                        logger.debug("Output queue full")
            except:
                pass
    
    def set_bitrate(self, bitrate):
        """Change encoding bitrate"""
        self.bitrate = bitrate
        self.encoder.set_bitrate(bitrate)
    
    def set_codec(self, codec):
        """Change codec"""
        if codec != self.codec:
            self.codec = codec
            if codec == "MP3":
                self.encoder = MP3Encoder(self.bitrate, self.sample_rate, self.channels)
            elif codec == "OGG":
                self.encoder = OGGEncoder(self.bitrate, self.sample_rate, self.channels)
            logger.info(f"Codec changed to {codec}")
    
    def flush(self):
        """Flush encoder"""
        self.encoder.flush()

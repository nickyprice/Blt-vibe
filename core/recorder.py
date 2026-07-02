#!/usr/bin/env python3
"""
Advanced Recording Manager - WAV and MP3 local recording
"""

import logging
import wave
import os
from datetime import datetime
from threading import Thread, Lock, Event
from queue import Queue
import numpy as np

logger = logging.getLogger(__name__)


class WaveRecorder:
    """WAV file recorder"""
    
    def __init__(self, output_path, sample_rate=44100, channels=2, bit_depth=16):
        self.output_path = output_path
        self.sample_rate = sample_rate
        self.channels = channels
        self.bit_depth = bit_depth
        self.wave_file = None
        self.is_recording = False
        
        logger.info(f"WaveRecorder initialized - Output: {output_path}")
    
    def start(self):
        """Start recording to WAV file"""
        try:
            os.makedirs(os.path.dirname(self.output_path), exist_ok=True)
            
            self.wave_file = wave.open(self.output_path, 'wb')
            self.wave_file.setnchannels(self.channels)
            self.wave_file.setsampwidth(self.bit_depth // 8)
            self.wave_file.setframerate(self.sample_rate)
            
            self.is_recording = True
            logger.info(f"Started recording to {self.output_path}")
            return True
        except Exception as e:
            logger.error(f"Error starting WAV recording: {e}")
            return False
    
    def write(self, audio_data):
        """Write audio data to WAV file"""
        try:
            if self.is_recording and self.wave_file:
                if isinstance(audio_data, np.ndarray):
                    audio_data = audio_data.astype(np.int16).tobytes()
                self.wave_file.writeframes(audio_data)
        except Exception as e:
            logger.error(f"Error writing to WAV file: {e}")
    
    def stop(self):
        """Stop recording"""
        try:
            if self.wave_file:
                self.wave_file.close()
            self.is_recording = False
            logger.info(f"Stopped recording. File saved: {self.output_path}")
            return True
        except Exception as e:
            logger.error(f"Error stopping WAV recording: {e}")
            return False


class RecorderManager:
    """Manages local audio recording"""
    
    def __init__(self, output_directory="./recordings"):
        self.output_directory = output_directory
        self.recorder = None
        self.record_queue = Queue(maxsize=100)
        self.record_thread = None
        self.is_recording = False
        self.stop_event = Event()
        self.lock = Lock()
        
        logger.info("RecorderManager initialized")
    
    def start_recording(self):
        """Start recording to local file"""
        with self.lock:
            try:
                # Generate filename with timestamp
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"blt_vibe_{timestamp}.wav"
                output_path = os.path.join(self.output_directory, filename)
                
                # Create recorder
                self.recorder = WaveRecorder(output_path)
                
                if self.recorder.start():
                    self.is_recording = True
                    self.stop_event.clear()
                    
                    # Start recording thread
                    self.record_thread = Thread(target=self._record_loop, daemon=True)
                    self.record_thread.start()
                    
                    logger.info(f"Recording started: {filename}")
                    return True
                else:
                    return False
            except Exception as e:
                logger.error(f"Error starting recording: {e}")
                return False
    
    def stop_recording(self):
        """Stop recording"""
        with self.lock:
            try:
                self.stop_event.set()
                self.is_recording = False
                
                if self.recorder:
                    if self.recorder.stop():
                        logger.info("Recording stopped successfully")
                        self.recorder = None
                        return True
                
                return False
            except Exception as e:
                logger.error(f"Error stopping recording: {e}")
                return False
    
    def add_audio(self, audio_data):
        """Queue audio data for recording"""
        if self.is_recording:
            try:
                self.record_queue.put_nowait(audio_data)
            except:
                logger.debug("Record queue full, dropping frame")
    
    def _record_loop(self):
        """Recording loop"""
        while not self.stop_event.is_set() and self.is_recording:
            try:
                audio_data = self.record_queue.get(timeout=1)
                if self.recorder and audio_data is not None:
                    self.recorder.write(audio_data)
            except:
                pass
    
    def get_recording_status(self):
        """Get current recording status"""
        return {
            "is_recording": self.is_recording,
            "queue_size": self.record_queue.qsize()
        }

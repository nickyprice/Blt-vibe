#!/usr/bin/env python3
"""
BLT Vibe - Main Application
Broadcast Live Transmission Vibe - Desktop streaming client for radio DJs
"""

import sys
import logging
import json
import os
from datetime import datetime
from pathlib import Path

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QTabWidget, QLabel, QLineEdit, QPushButton, QComboBox, QSpinBox,
    QProgressBar, QCheckBox, QMessageBox, QFileDialog, QGroupBox,
    QFormLayout, QTextEdit
)
from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QThread
from PyQt6.QtGui import QFont, QIcon

# Import core modules
from core.streamer import StreamerManager
from core.encoder import AudioEncoder
from core.recorder import RecorderManager

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('blt_vibe.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class AudioInputThread(QThread):
    """Thread for audio input processing"""
    audio_level_updated = pyqtSignal(float)
    
    def __init__(self):
        super().__init__()
        self.is_running = False
    
    def run(self):
        """Run audio input thread"""
        try:
            import pyaudio
            import numpy as np
            
            self.is_running = True
            p = pyaudio.PyAudio()
            
            # Get default input device
            device_index = p.get_default_input_device_info()
            
            stream = p.open(
                format=pyaudio.paFloat32,
                channels=2,
                rate=44100,
                input=True,
                frames_per_buffer=2048
            )
            
            while self.is_running:
                try:
                    data = stream.read(2048, exception_on_overflow=False)
                    audio_data = np.frombuffer(data, dtype=np.float32)
                    level = np.sqrt(np.mean(audio_data ** 2))
                    self.audio_level_updated.emit(min(level * 10, 1.0))
                except Exception as e:
                    logger.error(f"Audio input error: {e}")
            
            stream.stop_stream()
            stream.close()
            p.terminate()
        except Exception as e:
            logger.error(f"Audio thread error: {e}")
    
    def stop(self):
        """Stop audio thread"""
        self.is_running = False


class BLTVibeApp(QMainWindow):
    """Main BLT Vibe Application Window"""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("BLT Vibe - Live Streaming")
        self.setGeometry(100, 100, 800, 600)
        
        # Initialize managers
        self.streamer = StreamerManager()
        self.encoder = None
        self.recorder = RecorderManager()
        self.audio_thread = None
        
        # Load config
        self.config = self.load_config()
        
        # Setup UI
        self.setup_ui()
        
        # Start audio input thread
        self.start_audio_thread()
        
        logger.info("BLT Vibe Application started")
    
    def load_config(self):
        """Load configuration from file"""
        try:
            if os.path.exists('config.json'):
                with open('config.json', 'r') as f:
                    return json.load(f)
            elif os.path.exists('config.example.json'):
                with open('config.example.json', 'r') as f:
                    return json.load(f)
        except Exception as e:
            logger.error(f"Error loading config: {e}")
        
        return self.get_default_config()
    
    def get_default_config(self):
        """Get default configuration"""
        return {
            "audio": {
                "sample_rate": 44100,
                "channels": 2,
                "bit_depth": 16
            },
            "streaming": {
                "shoutcast": {
                    "enabled": True,
                    "host": "",
                    "port": 8000,
                    "mount_point": "/stream",
                    "password": "",
                    "bitrate": 128
                },
                "icecast": {
                    "enabled": False,
                    "host": "",
                    "port": 8000,
                    "mount_point": "/stream",
                    "password": "",
                    "bitrate": 128
                }
            },
            "metadata": {
                "source": "manual",
                "manual": {
                    "artist": "",
                    "title": "",
                    "on_air": ""
                }
            }
        }
    
    def setup_ui(self):
        """Setup user interface"""
        # Create central widget and main layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        
        # Create tab widget
        self.tabs = QTabWidget()
        main_layout.addWidget(self.tabs)
        
        # Tab 1: Audio Input
        self.setup_audio_input_tab()
        
        # Tab 2: Streaming Configuration
        self.setup_streaming_tab()
        
        # Tab 3: Metadata
        self.setup_metadata_tab()
        
        # Control buttons layout
        button_layout = QHBoxLayout()
        
        self.start_btn = QPushButton("▶ Start Streaming")
        self.start_btn.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 10px;")
        self.start_btn.clicked.connect(self.start_streaming)
        button_layout.addWidget(self.start_btn)
        
        self.stop_btn = QPushButton("⏹ Stop Streaming")
        self.stop_btn.setStyleSheet("background-color: #f44336; color: white; font-weight: bold; padding: 10px;")
        self.stop_btn.clicked.connect(self.stop_streaming)
        self.stop_btn.setEnabled(False)
        button_layout.addWidget(self.stop_btn)
        
        self.record_btn = QPushButton("⭕ Record")
        self.record_btn.setStyleSheet("background-color: #FF5722; color: white; font-weight: bold; padding: 10px;")
        self.record_btn.clicked.connect(self.toggle_recording)
        button_layout.addWidget(self.record_btn)
        
        main_layout.addLayout(button_layout)
        
        # Status bar
        self.status_label = QLabel("🔴 Ready")
        self.status_label.setFont(QFont("Arial", 12, QFont.Weight.Bold))
        main_layout.addWidget(self.status_label)
    
    def setup_audio_input_tab(self):
        """Setup Audio Input tab"""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        # Audio device selection
        device_group = QGroupBox("Audio Input Device")
        device_layout = QFormLayout()
        
        self.device_combo = QComboBox()
        self.device_combo.addItems(["USB Mixer", "Built-in Microphone", "Line In"])
        device_layout.addRow("Device:", self.device_combo)
        
        device_group.setLayout(device_layout)
        layout.addWidget(device_group)
        
        # Audio levels
        level_group = QGroupBox("Audio Levels")
        level_layout = QVBoxLayout()
        
        level_label = QLabel("Input Level:")
        level_layout.addWidget(level_label)
        
        self.level_bar = QProgressBar()
        self.level_bar.setMinimum(0)
        self.level_bar.setMaximum(100)
        self.level_bar.setValue(0)
        level_layout.addWidget(self.level_bar)
        
        self.level_text = QLabel("0%")
        level_layout.addWidget(self.level_text)
        
        level_group.setLayout(level_layout)
        layout.addWidget(level_group)
        
        layout.addStretch()
        self.tabs.addTab(widget, "🎙️ Audio Input")
    
    def setup_streaming_tab(self):
        """Setup Streaming Configuration tab"""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        # Shoutcast Configuration
        shoutcast_group = QGroupBox("Shoutcast Server")
        shoutcast_layout = QFormLayout()
        
        self.shoutcast_host = QLineEdit()
        self.shoutcast_host.setText(self.config['streaming']['shoutcast'].get('host', ''))
        shoutcast_layout.addRow("Host:", self.shoutcast_host)
        
        self.shoutcast_port = QSpinBox()
        self.shoutcast_port.setValue(self.config['streaming']['shoutcast'].get('port', 8000))
        shoutcast_layout.addRow("Port:", self.shoutcast_port)
        
        self.shoutcast_password = QLineEdit()
        self.shoutcast_password.setEchoMode(QLineEdit.EchoMode.Password)
        self.shoutcast_password.setText(self.config['streaming']['shoutcast'].get('password', ''))
        shoutcast_layout.addRow("Password:", self.shoutcast_password)
        
        self.shoutcast_mount = QLineEdit()
        self.shoutcast_mount.setText(self.config['streaming']['shoutcast'].get('mount_point', '/stream'))
        shoutcast_layout.addRow("Mount Point:", self.shoutcast_mount)
        
        self.shoutcast_enabled = QCheckBox("Enable Shoutcast")
        self.shoutcast_enabled.setChecked(self.config['streaming']['shoutcast'].get('enabled', True))
        shoutcast_layout.addRow(self.shoutcast_enabled)
        
        shoutcast_group.setLayout(shoutcast_layout)
        layout.addWidget(shoutcast_group)
        
        # Icecast Configuration
        icecast_group = QGroupBox("Icecast Server")
        icecast_layout = QFormLayout()
        
        self.icecast_host = QLineEdit()
        self.icecast_host.setText(self.config['streaming']['icecast'].get('host', ''))
        icecast_layout.addRow("Host:", self.icecast_host)
        
        self.icecast_port = QSpinBox()
        self.icecast_port.setValue(self.config['streaming']['icecast'].get('port', 8000))
        icecast_layout.addRow("Port:", self.icecast_port)
        
        self.icecast_password = QLineEdit()
        self.icecast_password.setEchoMode(QLineEdit.EchoMode.Password)
        self.icecast_password.setText(self.config['streaming']['icecast'].get('password', ''))
        icecast_layout.addRow("Password:", self.icecast_password)
        
        self.icecast_mount = QLineEdit()
        self.icecast_mount.setText(self.config['streaming']['icecast'].get('mount_point', '/stream'))
        icecast_layout.addRow("Mount Point:", self.icecast_mount)
        
        self.icecast_enabled = QCheckBox("Enable Icecast")
        self.icecast_enabled.setChecked(self.config['streaming']['icecast'].get('enabled', False))
        icecast_layout.addRow(self.icecast_enabled)
        
        icecast_group.setLayout(icecast_layout)
        layout.addWidget(icecast_group)
        
        layout.addStretch()
        self.tabs.addTab(widget, "🔊 Streaming")
    
    def setup_metadata_tab(self):
        """Setup Metadata tab"""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        metadata_group = QGroupBox("Currently Playing")
        metadata_layout = QFormLayout()
        
        self.artist_input = QLineEdit()
        self.artist_input.setText(self.config['metadata']['manual'].get('artist', ''))
        metadata_layout.addRow("Artist:", self.artist_input)
        
        self.title_input = QLineEdit()
        self.title_input.setText(self.config['metadata']['manual'].get('title', ''))
        metadata_layout.addRow("Title:", self.title_input)
        
        self.on_air_input = QLineEdit()
        self.on_air_input.setText(self.config['metadata']['manual'].get('on_air', ''))
        metadata_layout.addRow("On Air:", self.on_air_input)
        
        update_btn = QPushButton("Update Metadata")
        update_btn.clicked.connect(self.update_metadata)
        metadata_layout.addRow(update_btn)
        
        metadata_group.setLayout(metadata_layout)
        layout.addWidget(metadata_group)
        
        layout.addStretch()
        self.tabs.addTab(widget, "🎵 Metadata")
    
    def start_audio_thread(self):
        """Start audio input thread"""
        try:
            self.audio_thread = AudioInputThread()
            self.audio_thread.audio_level_updated.connect(self.update_audio_level)
            self.audio_thread.start()
        except Exception as e:
            logger.error(f"Error starting audio thread: {e}")
    
    def update_audio_level(self, level):
        """Update audio level display"""
        self.level_bar.setValue(int(level * 100))
        self.level_text.setText(f"{int(level * 100)}%")
    
    def start_streaming(self):
        """Start streaming"""
        try:
            # Get configuration
            if self.shoutcast_enabled.isChecked():
                if not self.shoutcast_host.text():
                    QMessageBox.warning(self, "Error", "Please enter Shoutcast host")
                    return
                
                self.streamer.connect_shoutcast(
                    host=self.shoutcast_host.text(),
                    port=self.shoutcast_port.value(),
                    password=self.shoutcast_password.text(),
                    mount=self.shoutcast_mount.text()
                )
            
            if self.icecast_enabled.isChecked():
                if not self.icecast_host.text():
                    QMessageBox.warning(self, "Error", "Please enter Icecast host")
                    return
                
                self.streamer.connect_icecast(
                    host=self.icecast_host.text(),
                    port=self.icecast_port.value(),
                    password=self.icecast_password.text(),
                    mount=self.icecast_mount.text()
                )
            
            self.start_btn.setEnabled(False)
            self.stop_btn.setEnabled(True)
            self.status_label.setText("🟢 STREAMING")
            self.status_label.setStyleSheet("color: green; font-weight: bold;")
            
            logger.info("Streaming started")
            QMessageBox.information(self, "Success", "Streaming started successfully!")
        except Exception as e:
            logger.error(f"Error starting streaming: {e}")
            QMessageBox.critical(self, "Error", f"Failed to start streaming: {e}")
    
    def stop_streaming(self):
        """Stop streaming"""
        try:
            self.streamer.disconnect()
            
            self.start_btn.setEnabled(True)
            self.stop_btn.setEnabled(False)
            self.status_label.setText("🔴 Ready")
            self.status_label.setStyleSheet("color: red; font-weight: bold;")
            
            logger.info("Streaming stopped")
            QMessageBox.information(self, "Success", "Streaming stopped")
        except Exception as e:
            logger.error(f"Error stopping streaming: {e}")
            QMessageBox.critical(self, "Error", f"Failed to stop streaming: {e}")
    
    def toggle_recording(self):
        """Toggle recording"""
        try:
            if self.recorder.is_recording:
                self.recorder.stop_recording()
                self.record_btn.setText("⭕ Record")
                self.record_btn.setStyleSheet("background-color: #FF5722; color: white; font-weight: bold; padding: 10px;")
                logger.info("Recording stopped")
            else:
                self.recorder.start_recording()
                self.record_btn.setText("⏹ Stop Recording")
                self.record_btn.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold; padding: 10px;")
                logger.info("Recording started")
        except Exception as e:
            logger.error(f"Error toggling recording: {e}")
            QMessageBox.critical(self, "Error", f"Recording error: {e}")
    
    def update_metadata(self):
        """Update metadata"""
        try:
            metadata = {
                'artist': self.artist_input.text(),
                'title': self.title_input.text(),
                'on_air': self.on_air_input.text()
            }
            self.streamer.update_metadata(metadata)
            logger.info(f"Metadata updated: {metadata}")
            QMessageBox.information(self, "Success", "Metadata updated")
        except Exception as e:
            logger.error(f"Error updating metadata: {e}")
            QMessageBox.critical(self, "Error", f"Failed to update metadata: {e}")
    
    def closeEvent(self, event):
        """Handle window close event"""
        try:
            self.streamer.disconnect()
            if self.recorder.is_recording:
                self.recorder.stop_recording()
            if self.audio_thread:
                self.audio_thread.stop()
                self.audio_thread.wait()
        except Exception as e:
            logger.error(f"Error closing application: {e}")
        event.accept()


def main():
    """Main entry point"""
    app = QApplication(sys.argv)
    window = BLTVibeApp()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

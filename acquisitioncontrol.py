# Copyright (C) 2023, BRAIN-LINK UG (haftungsbeschränkt). All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0-only OR LicenseRef-ScanHub-Commercial

"""Contains the definition of the AcquisitionControl and the ThreadedHttpServer class."""

import json
import os
import queue
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import numpy as np
import requests
from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtWidgets import (QApplication, QLabel, QPushButton, QVBoxLayout,
                               QWidget)
from scanhub import AcquisitionCommand, AcquisitionEvent


class RequestHandler(BaseHTTPRequestHandler):
    """A class which handles the HTTP requests."""

    def do_POST(self):
        """Handle the POST requests."""
        if self.path == "/api/start-scan":
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            payload = json.loads(post_data)

            # Access the payload data
            record_id = payload["record_id"]
            sequence = payload["sequence"]

            acquisition_event = AcquisitionEvent(
                device_id="Simulator",
                record_id=record_id,
                command_id=AcquisitionCommand.start,
                input_sequence=sequence,
            )

            # Call the start-scan method of the AcquisitionControl instance
            self.server.acquisition_control.start_simulation(acquisition_event)

            # Send response back to the client
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            response = {"message": "Simulation started"}
            self.wfile.write(json.dumps(response).encode())
        else:
            # Send 404 error for unknown endpoints
            self.send_response(404)
            self.end_headers()


class ThreadedHttpServer:
    """A class which creates a threaded HTTP server."""

    def __init__(self, host, port, acquisition_control):
        """Initialize the ThreadedHttpServer class."""
        self.host = host
        self.port = port
        self.acquisition_control = acquisition_control

    def start(self):
        """Start the HTTP server."""
        server_address = (self.host, self.port)
        self.httpd = HTTPServer(server_address, RequestHandler)
        RequestHandler.server = (
            self.httpd
        )  # Pass the server instance to the request handler
        # Pass the AcquisitionControl instance to the request handler
        RequestHandler.server.acquisition_control = self.acquisition_control
        server_thread = threading.Thread(target=self.httpd.serve_forever)
        server_thread.start()

    def stop(self):
        """Stop the HTTP server."""
        if self.httpd:
            self.httpd.shutdown()
            self.httpd.server_close()


class AcquisitionControl(QObject):
    """A class which contains methods to communicate with the ScanHub.

    This class will establish a connection to ScanHub and receive/send commands
    """

    signalStatus = Signal(str)

    signalStart = Signal()

    signalStartMeasurement = Signal()
    signalStopMeasurement = Signal()
    signalPauseMeasurement = Signal()

    _acquisition_queue: queue.Queue[AcquisitionEvent] = queue.Queue()

    def __init__(self, account_name, account_key, scanhub_id, parent=None):
        super(self.__class__, self).__init__(parent)

        # Create the threaded http server
        self._threaded_http_server = ThreadedHttpServer("localhost", 5000, self)

        # Set the ScanHub ID
        self._scanhub_id = scanhub_id

        # Make any cross object connections.
        self._connectSignals()

        # Start the HTTP server
        self._threaded_http_server.start()

    def __del__(self):
        """Destructor of the class."""
        self.forceWorkerQuit()

    def start_simulation(self, acquisition_event: AcquisitionEvent):
        """Start the simulation."""
        print("Starting simulation...")
        print(acquisition_event)

        self.signalStatus.emit("Starting simulation...")
        self._acquisition_queue.put(acquisition_event)
        self.signalStartMeasurement.emit()

    def _connectSignals(self):
        """Connect signals and slots."""
        self.parent().aboutToQuit.connect(self.forceWorkerQuit)

    def forceWorkerQuit(self):
        """Force the worker to quit."""
        # Stop the HTTP server when needed
        self._threaded_http_server.stop()

    # @Slot()
    # def processCommand(self, acquisition_event: AcquisitionEvent) -> bool:
    #     print(f'Process Event')
    #     match acquisition_event.command_id:
    #         case AcquisitionCommand.start:
    #             print(AcquisitionCommand.start)
    #             self._acquisition_queue.put(acquisition_event)
    #             self.signalStartMeasurement.emit()
    #             return True
    #         case AcquisitionCommand.stop:
    #             print(AcquisitionCommand.stop)
    #             self.signalStopMeasurement.emit()
    #             return True
    #         case AcquisitionCommand.pause:
    #             print(AcquisitionCommand.pause)
    #             self.signalPauseMeasurement.emit()
    #             return True
    #         # default
    #         case _:
    #             return False

    def upload_data_to_blob(self, array: np.ndarray, container_name):
        """Upload the data to the blob storage."""
        try:
            tmp_directory_path = os.fspath(Path(__file__).resolve().parent / "tmp")

            # If folder doesn't exist, then create it.
            if not os.path.isdir(tmp_directory_path):
                os.makedirs(tmp_directory_path)
                print(f"created directory : {tmp_directory_path}")

            tmp_file_path = os.fspath(Path(__file__).resolve().parent / "tmp/data.npy")

            print(f"save data to {tmp_file_path}")
            np.save(tmp_file_path, array)

            acquisition_event = self._acquisition_queue.get()

            print(f"finished acquisition_event : {acquisition_event}")

            file = {"file": open(tmp_file_path, "rb")}
            url = f"http://localhost:8080/api/v1/workflow/upload/{acquisition_event.record_id}"

            print(f"uploading to {url}")

            r = requests.post(url, files=file)
            print(r.json())
            return True

        except Exception as e:
            print(e)
            return False


# DEBUG CODE STARTING HERE
class Window(QWidget):
    """A class which contains a simple debug GUI."""

    def __init__(self):
        """Initialize the Window class."""
        QWidget.__init__(self)
        self.button_start = QPushButton("Start", self)
        self.button_cancel = QPushButton("Cancel", self)
        self.label_status = QLabel("", self)

        layout = QVBoxLayout(self)
        layout.addWidget(self.button_start)
        layout.addWidget(self.button_cancel)
        layout.addWidget(self.label_status)

        self.setFixedSize(400, 200)

    @Slot(str)
    def updateStatus(self, status):
        """Update the status label."""
        self.label_status.setText(status)

    @Slot(str)
    def startMeasurement(self):
        """Update the status label."""
        self.label_status.setText("Start Measurement")

    @Slot(str)
    def stopMeasurement(self):
        """Update the status label."""
        self.label_status.setText("Stop Measurement")

    @Slot(str)
    def pauseMeasurement(self):
        """Update the status label."""
        self.label_status.setText("Pause Measurement")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    control = AcquisitionControl(app)

    # Create a gui object.
    gui = Window()
    gui.button_cancel.clicked.connect(control.forceWorkerReset)
    control.signalStatus.connect(gui.updateStatus)
    control.signalStartMeasurement.connect(gui.startMeasurement)
    control.signalStopMeasurement.connect(gui.stopMeasurement)
    control.signalPauseMeasurement.connect(gui.pauseMeasurement)
    gui.button_start.clicked.connect(control.signalStart)
    gui.show()

    sys.exit(app.exec())

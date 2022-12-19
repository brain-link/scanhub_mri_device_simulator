#!/usr/bin/env python
# -*- conding: utf-8 -*-
import sys
import random

import time, os
import requests
import uuid

import numpy as np

from kafka import KafkaConsumer
import json

from AcquisitionEvent import AcquisitionEvent

from PySide6.QtCore import QObject, QThread, Signal, Slot
from pathlib import Path

from PySide6.QtWidgets import (
        QApplication,
        QWidget,
        QPushButton,
        QLabel,
        QVBoxLayout
)
from PySide6 import QtGui

from enum import Enum

from azure.core.exceptions import ResourceExistsError

from azure.storage.queue import (
        QueueClient,
        BinaryBase64EncodePolicy,
        BinaryBase64DecodePolicy
)

from azure.storage.blob import (
    BlobClient, 
    BlobServiceClient, 
    ContainerClient
)

class AcquisitionCommands(Enum):
    """A class which contains the commands for the acquisition control.

    The commands are defined as an enum.
    """
    # MEASURMENT
    MEAS_START = 1000
    MEAS_STOP = 1001
    MEAS_PAUSE = 1002


class AcquisitionControl(QObject):
    """A class which contains methods to communicate with the ScanHub

    This class will establish a connection to ScanHub and receive/send commands
    """

    signalStatus = Signal(str)

    signalStart = Signal()

    signalStartMeasurement = Signal()
    signalStopMeasurement = Signal()
    signalPauseMeasurement = Signal()

    def __init__(self, account_name, account_key, scanhub_id, parent=None):
        super(self.__class__, self).__init__(parent)

        # Set AZURE_STORAGE_CONNECTION_STRING
        self._connect_str = 'DefaultEndpointsProtocol=http;AccountName=' + account_name + ';AccountKey=' + account_key + ';BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;'

        # Set the ScanHub ID
        self._scanhub_id = scanhub_id

        # Create a new worker thread.
        self.createWorkerThread()

        # Make any cross object connections.
        self._connectSignals()

    def _connectSignals(self):
        self.parent().aboutToQuit.connect(self.forceWorkerQuit)

    def createWorkerThread(self):
        # Setup the worker object and the worker_thread.
        self._command_worker = CommandWorkerThread(self._connect_str)
        self._command_worker_thread = QThread()
        self._command_worker.moveToThread(self._command_worker_thread)
        self._command_worker_thread.start()

        # Connect any worker signals
        self._command_worker.signalStatus.connect(self.signalStatus)
        self._command_worker.signalCommand.connect(self.processCommand)
        self.signalStart.connect(self._command_worker.startWork)

    @Slot()
    def forceWorkerReset(self):      
        if self._command_worker_thread.isRunning():
            print('Terminating thread.')
            self._command_worker_thread.terminate()

            print('Waiting for thread termination.')
            self._command_worker_thread.wait()

            self.signalStatus.emit('Idle.')

            print('building new working object.')
            self.createWorkerThread()

    def forceWorkerQuit(self):
        if self._command_worker_thread.isRunning():
            self._command_worker_thread.terminate()
            self._command_worker_thread.wait()

    @Slot()
    def processCommand(self, acquisitionCommand: AcquisitionCommands) -> bool:
        print('Process Command')
        match acquisitionCommand:
            case AcquisitionCommands.MEAS_START:
                print(AcquisitionCommands.MEAS_START)
                self.signalStartMeasurement.emit()
                return True
            case AcquisitionCommands.MEAS_STOP:
                print(AcquisitionCommands.MEAS_STOP)
                self.signalStopMeasurement.emit()
                return True
            case AcquisitionCommands.MEAS_PAUSE:
                print(AcquisitionCommands.MEAS_PAUSE)
                self.signalPauseMeasurement.emit()
                return True
            # default
            case _:
                return False

    def upload_data_to_blob(self, array: np.ndarray, container_name):
        try:

            tmp_directory_path = os.fspath(Path(__file__).resolve().parent / "tmp")

            # If folder doesn't exist, then create it.
            if not os.path.isdir(tmp_directory_path):
                os.makedirs(tmp_directory_path)
                print("created directory : ", tmp_directory_path)

            tmp_file_path = os.fspath(Path(__file__).resolve().parent / "tmp/data.npy")

            print("save data to " + tmp_file_path)
            np.save(tmp_file_path, array)
            
            file = {'file': open(tmp_file_path,'rb')}
            url = f"http://localhost:8080/api/v1/devices/mri_simulator/result/{uuid.uuid4()}"

            r = requests.post(url, files=file)
            print(r.json())
            return True

        except Exception as e:
            print(e)
            return False


class CommandWorkerThread(QObject):
    """A class that implements the acquisiton control worker thread
    """
    signalStatus = Signal(str)
    signalCommand = Signal(AcquisitionCommands)

    def __init__(self, connect_str: str, parent=None):
        super(self.__class__, self).__init__(parent)
        self._connect_str = connect_str

    @Slot()
    def startWork(self) -> None:
        print('> Start Acquisition Control Worker <')
        consumer = KafkaConsumer('acquisitionEvent',
                                value_deserializer=lambda x: json.loads(x.decode('utf-8')), 
                                bootstrap_servers=['localhost:9092'])

        for message in consumer:
            acquisitionEvent = AcquisitionEvent(**(message.value))
            print("Received: " + acquisitionEvent.instruction)

            if self.parseCommand(acquisitionEvent.instruction):
                print('Commmand found.')
            else:
                print("Command not found.")
        print('> Stop Acquisition Control Worker <')

    def parseCommand(self, command: str) -> bool:
        for acquisitionCommand in AcquisitionCommands:
            if acquisitionCommand.name == command:
                self.signalCommand.emit(acquisitionCommand)
                return True
        return False



#DEBUG CODE STARTING HERE
class Window(QWidget):
    def __init__(self):
        QWidget.__init__(self)
        self.button_start = QPushButton('Start', self)
        self.button_cancel = QPushButton('Cancel', self)
        self.label_status = QLabel('', self)

        layout = QVBoxLayout(self)
        layout.addWidget(self.button_start)
        layout.addWidget(self.button_cancel)
        layout.addWidget(self.label_status)

        self.setFixedSize(400, 200)

    @Slot(str)
    def updateStatus(self, status):
        self.label_status.setText(status)

    @Slot(str)
    def startMeasurement(self):
        self.label_status.setText('Start Measurement')

    @Slot(str)
    def stopMeasurement(self):
        self.label_status.setText('Stop Measurement')

    @Slot(str)
    def pauseMeasurement(self):
        self.label_status.setText('Pause Measurement')


if __name__=='__main__':
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

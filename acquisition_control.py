#!/usr/bin/env python
# -*- conding: utf-8 -*-
from PySide6.QtCore import QObject, QThread, Signal, Slot


import sys
import random

import time, os

from PySide6.QtWidgets import (
        QApplication,
        QWidget,
        QPushButton,
        QLabel,
        QVBoxLayout
)
from PySide6 import QtGui

from enum import Enum

from azure.storage.queue import (
        QueueClient,
        BinaryBase64EncodePolicy,
        BinaryBase64DecodePolicy
)


#if __name__ == '__main__':
#    print("AcquisitionControl started")

#    # DEBUG
#    os.environ['STORAGE_CONNECTION_STRING'] = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;'

#    # Retrieve the connection string from an environment
#    # variable named AZURE_STORAGE_CONNECTION_STRING
#    connect_str = os.getenv("STORAGE_CONNECTION_STRING")

#    # queue name
#    q_name_tasks = "acquisition-control-queue"
#    q_name_results = "acquistion-control-results-queue"

#    # connect to queue
#    queue_client_tasks = QueueClient.from_connection_string(connect_str, q_name_tasks,
#                            message_encode_policy = BinaryBase64EncodePolicy(),
#                            message_decode_policy = BinaryBase64DecodePolicy())
#    queue_client_results = QueueClient.from_connection_string(connect_str, q_name_results,
#                            message_encode_policy = BinaryBase64EncodePolicy(),
#                            message_decode_policy = BinaryBase64DecodePolicy())
#    # queue_client_results.create_queue()
#    while(True):
#        messages = queue_client_tasks.receive_messages()

#        for message in messages:
#            print(message)
#            print("Dequeueing message: " + message.content.decode('UTF-8'))
#            queue_client_tasks.delete_message(message.id, message.pop_receipt)

#            print("Adding message: " + message.content.decode('UTF-8'))
#            queue_client_results.send_message(message.content)

#        time.sleep(1)


class AcquisitionCommands(Enum):

    # MEASURMENT
    MEAS_START = 1000
    MEAS_STOP = 1001
    MEAS_PAUSE = 1002


class AcquisitionControl(QObject):

    signalStatus = Signal(str)

    signalStart = Signal()

    signalStartMeasurement = Signal()
    signalStopMeasurement = Signal()
    signalPauseMeasurement = Signal()

    def __init__(self, parent=None):
        super(self.__class__, self).__init__(parent)

        # DEBUG
        os.environ['STORAGE_CONNECTION_STRING'] = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;'

        # Retrieve the connection string from an environment
        # variable named AZURE_STORAGE_CONNECTION_STRING
        self._connect_str = os.getenv("STORAGE_CONNECTION_STRING")

        # Create a new worker thread.
        self.createWorkerThread()

        # Make any cross object connections.
        self._connectSignals()

    def _connectSignals(self):
        self.parent().aboutToQuit.connect(self.forceWorkerQuit)


    def createWorkerThread(self):

        # Setup the worker object and the worker_thread.
        self.worker = WorkerThread(self._connect_str)
        self.worker_thread = QThread()
        self.worker.moveToThread(self.worker_thread)
        self.worker_thread.start()

        # Connect any worker signals
        self.worker.signalStatus.connect(self.signalStatus)
        self.worker.signalCommand.connect(self.processCommand)
        self.signalStart.connect(self.worker.startWork)

    @Slot()
    def forceWorkerReset(self):      
        if self.worker_thread.isRunning():
            print('Terminating thread.')
            self.worker_thread.terminate()

            print('Waiting for thread termination.')
            self.worker_thread.wait()

            self.signalStatus.emit('Idle.')

            print('building new working object.')
            self.createWorkerThread()

    def forceWorkerQuit(self):
        if self.worker_thread.isRunning():
            self.worker_thread.terminate()
            self.worker_thread.wait()

    @Slot()
    def processCommand(self, acquisitionCommand: AcquisitionCommands) -> bool:
        print('process Command')
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

class WorkerThread(QObject):

    signalStatus = Signal(str)
    signalCommand = Signal(AcquisitionCommands)

    def __init__(self, connect_str: str, parent=None):
        super(self.__class__, self).__init__(parent)
        self._connect_str = connect_str

    @Slot()
    def startWork(self) -> None:
        # queue name
        q_name_tasks = "acquisition-control-queue"
        q_name_results = "acquistion-control-results-queue"

        # connect to queue
        queue_client_tasks = QueueClient.from_connection_string(self._connect_str, q_name_tasks,
                                message_encode_policy = BinaryBase64EncodePolicy(),
                                message_decode_policy = BinaryBase64DecodePolicy())
        queue_client_results = QueueClient.from_connection_string(self._connect_str, q_name_results,
                                message_encode_policy = BinaryBase64EncodePolicy(),
                                message_decode_policy = BinaryBase64DecodePolicy())
        # queue_client_results.create_queue()

        print('> Start Acquisition Control Worker <')

        while(True):
            messages = queue_client_tasks.receive_messages()

            for message in messages:
                print(message)
                print("Dequeueing message: " + message.content.decode('UTF-8'))

                if self.parseCommand(message.content.decode('UTF-8')):
                    print('Commmand found.')
                    queue_client_tasks.delete_message(message.id, message.pop_receipt)
                else:
                    print("Command not found.")

                print("Adding message: " + message.content.decode('UTF-8'))
                queue_client_results.send_message(message.content)

            time.sleep(1)
        print('> Stop Acquisition Control Worker <')

    def parseCommand(self, command: str) -> bool:
        for acquisitionCommand in AcquisitionCommands:
            if acquisitionCommand.name == command:
                self.signalCommand.emit(acquisitionCommand)
                return True
        return False

#DEBUG
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

#!/usr/bin/env python
# -*- conding: utf-8 -*-
from PySide6.QtCore import QObject, QThread, Signal, Slot


import sys
import random
from PySide6.QtWidgets import QApplication, QWidget, QPushButton, QLabel, QVBoxLayout
from PySide6 import QtGui

class AcquisitionControl(QObject):

    signalStatus = Signal(str)
    signalStart = Signal()

    def __init__(self, parent=None):
        super(self.__class__, self).__init__(parent)

        # Create a new worker thread.
        self.createWorkerThread()

        # Make any cross object connections.
        self._connectSignals()

    def _connectSignals(self):
        self.parent().aboutToQuit.connect(self.forceWorkerQuit)


    def createWorkerThread(self):

        # Setup the worker object and the worker_thread.
        self.worker = WorkerThread()
        self.worker_thread = QThread()
        self.worker.moveToThread(self.worker_thread)
        self.worker_thread.start()

        # Connect any worker signals
        self.worker.signalStatus.connect(self.signalStatus)
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


class WorkerThread(QObject):
    signalStatus = Signal(str)

    def __init__(self, parent=None):
        super(self.__class__, self).__init__(parent)

    @Slot()
    def startWork(self):
        for ii in range(7):
            number = random.randint(0,5000**ii)
            self.signalStatus.emit('Iteration: {}, Factoring: {}'.format(ii, number))
            factors = self.primeFactors(number)
            print('Number: ', number, 'Factors: ', factors)
        self.signalStatus.emit('Idle.')

    def primeFactors(self, n):
        i = 2
        factors = []
        while i * i <= n:
            if n % i:
                i += 1
            else:
                n //= i
                factors.append(i)
        if n > 1:
            factors.append(n)
        return factors


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

if __name__=='__main__':
    app = QApplication(sys.argv)
    control = AcquisitionControl(app)
   
    # Create a gui object.
    gui = Window()
    gui.button_cancel.clicked.connect(control.forceWorkerReset)
    control.signalStatus.connect(gui.updateStatus)
    gui.button_start.clicked.connect(control.signalStart)
    gui.show()

    sys.exit(app.exec())

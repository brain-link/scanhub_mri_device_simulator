#!/usr/bin/env python
# -*- conding: utf-8 -*-
import os
import sys
import numpy as np

from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Signal


class SimulationView(QQmlApplicationEngine):

    def __init__(self,  parent=None):
        # Call super class
        super(SimulationView, self).__init__(parent)


        # Expose the ... to the QML code
        # self.rootContext().setContextProperty("", self.)

        # Connects here

        # Load the QML file
        qml_file = os.path.join(os.path.dirname(__file__), "views/view.qml")

        self.load(qml_file)
        if not self.rootObjects():
            sys.exit(-1)

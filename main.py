# Copyright (C) 2023, BRAIN-LINK UG (haftungsbeschränkt). All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0-only OR LicenseRef-ScanHub-Commercial

"""Contains the main application entry point."""

import logging.config
import os
import sys
from pathlib import Path

# from PySide6.QtCore import qInstallMessageHandler
from PySide6.QtGui import QFontDatabase, QIcon
from PySide6.QtWidgets import QApplication

from simulationapp import SimulationApp

# Logging setup
logging.config.fileConfig(fname="logging.conf", disable_existing_loggers=False)
log = logging.getLogger(__name__)
if len(sys.argv) > 1:
    log.setLevel("DEBUG") if sys.argv[1] == "--log" else None
log.info("ScanHub MRI Simulator started")
log.info(f"Platform: {sys.platform}")
log.info(f"Python: {sys.version}")
if sys.version_info >= (3, 8):  # importlib.metadata needs Python 3.8 or newer
    from importlib.metadata import version

    log.info(
        f'Pillow: {version("Pillow")}, '
        f'PySide6: {version("PySide6")}, '
        f'numpy: {version("numpy")}, '
        f'pydicom: {version("pydicom")}'
    )
else:
    log.info("Pillow: n/a, PySide6: n/a, numpy: n/a, pydicom: n/a")


if __name__ == "__main__":
    """Main application entry point"""

    def qt_msg_handler(mode, context, message):
        """Handle Qt messages and catching Python exceptions.

        Parameters
        ----------
        mode : int
            Message mode.
        context : QMessageLogContext
            Message context.
        message : str
            Message text.
        """
        # https://doc.qt.io/qt-5/qtglobal.html#QtMsgType-enum
        # modes = ['Debug', 'Warning', 'Critical', 'Fatal', 'Info']
        py_log_lvl = [10, 30, 50, 0, 20]
        log.log(py_log_lvl[mode], f"{message}, ({context.file}:{context.line})")
        # For debugging
        # print("%s: %s (%s:%d, %s)" % (
        #     modes[mode], message, context.file, context.line, context.file))

    # qInstallMessageHandler(qt_msg_handler)

    app = QApplication(sys.argv)
    QFontDatabase.addApplicationFont(os.fspath(Path(__file__).resolve().parent / "resources/fontello.ttf"))
    app.setWindowIcon(QIcon(os.fspath(Path(__file__).resolve().parent / "resources/scanhub.ico")))

    app.setOrganizationName("ScanHub MRI Simulator")
    app.setOrganizationDomain("brain-link.de")
    app.setApplicationName("ScanHub MRI Simulator")

    simApp = SimulationApp(app)
    sys.exit(app.exec())

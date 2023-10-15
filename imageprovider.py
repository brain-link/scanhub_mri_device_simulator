# Copyright (C) 2023, BRAIN-LINK UG (haftungsbeschränkt). All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0-only OR LicenseRef-ScanHub-Commercial

"""Contains the ImageProvider class definition."""

from PySide6 import QtQuick
from PySide6.QtGui import QColor, QImage, QPixmap

from imagemanipulators import ImageManipulators


class ImageProvider(QtQuick.QQuickImageProvider):
    """Contains the interface between numpy and Qt.

    Qt calls py_SimulationApp.update_displays on UI change
    that method requests new images to display
    pyqt channels it back to Qt GUI
    """

    def __init__(self, im: ImageManipulators):
        QtQuick.QQuickImageProvider.__init__(self, QtQuick.QQuickImageProvider.Pixmap)  # type: ignore
        self._im = im

    def requestPixmap(self, id_str: str, size, requested_size) -> QPixmap:
        """Qt calls this function when an image changes.

        Parameters
        ----------
            id_str : str
                identifies the requested image
            size : QSize
                This is used to set the width and height of the relevant Image.
            requested_size : QSize
                image size requested by QML (usually ignored)

        Returns
        -------
            QPixmap: an image in the format required by Qt
        """
        try:
            if id_str.startswith("image"):
                q_im = QImage(  # type: ignore
                    self._im.image_display_data,  # data
                    self._im.image_display_data.shape[1],  # width
                    self._im.image_display_data.shape[0],  # height
                    self._im.image_display_data.strides[0],  # bytes/line
                    QImage.Format_Grayscale8,  # type: ignore
                )  # format

            elif id_str.startswith("kspace"):
                q_im = QImage(  # type: ignore
                    self._im.kspace_display_data,  # data
                    self._im.kspace_display_data.shape[1],  # width
                    self._im.kspace_display_data.shape[0],  # height
                    self._im.kspace_display_data.strides[0],  # bytes/line
                    QImage.Format_Grayscale8,  # type: ignore
                )  # format

            elif id_str.startswith("thumb"):
                thumb_id = int(id_str[6 : 6 + id_str[6:].find("_")])
                im_c = py_SimulationApp.img_instances[thumb_id]  # type: ignore
                q_im = QImage(  # type: ignore
                    im_c.image_display_data,  # data
                    im_c.image_display_data.shape[1],  # width
                    im_c.image_display_data.shape[0],  # height
                    im_c.image_display_data.strides[0],  # bytes/line
                    QImage.Format_Grayscale8,  # type: ignore
                )  # format

            else:
                raise NameError

        except NameError:
            print(NameError)
            # On error, we return a red image of requested size
            q_im = QPixmap(requested_size)
            q_im.fill(QColor("red"))

        return QPixmap(q_im)  # , QPixmap(q_im).size()

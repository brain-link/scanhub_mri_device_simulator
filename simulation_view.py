#!/usr/bin/env python
# -*- conding: utf-8 -*-
import os
import pathlib
import sys
import numpy as np

import logging
log = logging.getLogger(__name__)

from uuid import uuid4

import logging.config
import PIL
import numpy as np
import pydicom
from pydicom import errors
from PIL import Image

from PySide6 import QtQuick
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Signal, Slot


from PySide6.QtCore import QObject, QUrl, qInstallMessageHandler, Qt

from PySide6.QtGui import QGuiApplication
from PySide6.QtGui import QImage, QPixmap, QColor

from PySide6.QtWidgets import QMessageBox

from image_manipulators import ImageManipulators

def qt_msgbox(text='', fatal=False):
    link = 'https://github.com/brain-link/scanhub-mri-device-simulator/issues'
    suffix = '\n\nA log file has been created.'
    if fatal:
        suffix += '\nScanHub MRI Simulator will quit.'
    error_text = f"Error - Get help on <a href='{link}'>GitHub</a>"

    msg = QMessageBox()
    msg.setIcon(QMessageBox.Critical)
    msg.setTextFormat(Qt.RichText)
    msg.setText(error_text)
    msg.setInformativeText(text + suffix)
    msg.setWindowTitle("Error")
    msg.exec()
    if fatal:
        sys.exit()
    else:
        return msg.result()


def open_file(path: str, dtype: np.dtype = np.float32) -> np.ndarray:
    """Tries to load image data into a NumPy ndarray

    The function first tries to use the PIL Image library to identify and load
    the image. PIL will convert the image to 8-bit pixels, black and white.
    If PIL fails pydicom is the next choice.

    Parameters:
        path (str): The image file location
        dtype (np.dtype): image array dtype (e.g. np.float64)

    Returns:
        np.ndarray: a floating point NumPy ndarray of the specified dtype
    """

    try:
        log.info(f'Opening file: {path}')
        with Image.open(path) as f:
            img_file = f.convert('F')  # 'F' mode: 32-bit floating point pixels
            img_pixel_array = np.array(img_file).astype(dtype)

        log.info(f"Image loaded. Image size: {img_pixel_array.shape}")
        return img_pixel_array
    except FileNotFoundError:
        log.error("File not found", exc_info=True)
        if 'im' not in globals():   # Quit gracefully if first start fails
            qt_msgbox(f"File not found. ({path}).", fatal=True)
    except PIL.UnidentifiedImageError:
        log.info(f'Filetype is not recognised by PIL. Trying pydicom.')
        try:
            with pydicom.dcmread(path) as dcm_file:
                img_pixel_array = dcm_file.pixel_array.astype(dtype)
            img_pixel_array.setflags(write=True)
            log.info(f"DICOM loaded. Image size: {img_pixel_array.shape}")
            return img_pixel_array
        except errors.InvalidDicomError:
            log.info(f'Cannot open with pydicom. Trying to open as raw data.')
            try:
                raw_data = np.load(path)
                log.info(f"Raw data loaded. Data size: {raw_data.shape}")
                return raw_data
            except Exception as e:
                log.error("Failed to open file", exc_info=True)
                raise e

class MainApp(QObject):
    """ Main App
    This class handles all interaction with the QML user interface
    """

    def __init__(self, context, parent=None):
        super().__init__(parent)

        self.win = parent
        self.ctx = context

        def bind(object_name: str) -> QtQuick.QQuickItem:
            """Finds the QML Object with the object name

            Parameters:
                object_name (str): UI element's objectName in QML file

            Returns:
                QQuickItem: Reference to the QQuickItem found by the function
            """
            return self.win.findChild(QObject, object_name)

        # List of QML control objectNames that we will bind to
        ctrls = ["image_display", "kspace_display", "noise_slider", "compress",
                 "decrease_dc", "partial_fourier_slider", "undersample_kspace",
                 "high_pass_slider", "low_pass_slider", "ksp_const", "filling",
                 "hamming", "rdc_slider", "zero_fill", "compress", "droparea",
                 "filling_mode", "thumbnails"]

        # Binding UI elements and controls
        for ctrl in ctrls:
            setattr(self, "ui_" + ctrl, bind(ctrl))

        # Initialise an empty list of image paths that can later be filled
        self.url_list = []
        self.current_img = 0
        self.file_data = []
        self.is_image = True
        self.channels = 1
        self.img_instances = {}

    def execute_load(self):
        """ Replaces the ImageManipulators class therefore changing the image

        Can be called by changing the image list (new image(s) opened) or by
        flipping through the existing list of images. If the image is not
        accessible or does not contain an image, it is removed from the list.
        """
        global im
        try:
            path = self.url_list[self.current_img]
            log.info(f"Changing to image: {path}")
            self.file_data = open_file(path)
            self.is_image = False if len(self.file_data.shape) > 2 else True
        except (FileNotFoundError, ValueError, AttributeError):
            # When the image is inaccessible at load time, the error
            qt_msgbox(f"Cannot load file ({self.url_list[self.current_img]})")
            del self.url_list[self.current_img]
            return

        if self.is_image:
            self.channels = 0
            self.img_instances = {}
            im = ImageManipulators(self.file_data, self.is_image)
        else:
            self.channels = self.file_data.shape[0]
            for channel in range(self.channels):
                # Extract 2D data slices from 3D array
                file_data = self.file_data[channel, :, :]
                self.img_instances[channel] = \
                    ImageManipulators(file_data, self.is_image)
            im = self.img_instances[0]

        # Let the QML thumbnails list know about the number of channels
        self.ui_thumbnails.setProperty("model", self.channels)

        self.update_displays()

        self.ui_droparea.setProperty("loaded_imgs", len(self.url_list))
        self.ui_droparea.setProperty("curr_img", self.current_img + 1)

    @Slot('QList<QUrl>', name="load_new_img")
    def load_new_img(self, urls: list):
        """ Image loader

        Loads an image from the specified path

        Parameters:
            urls: list of QUrls to be opened
        """
        log.info(f"New image list: {urls}")

        self.current_img = 0

        # Using QUrl.toLocalFile to convert list elements to strings
        self.url_list[:] = [s.toLocalFile() for s in urls]

        self.ui_droparea.setProperty("loaded_imgs", len(self.url_list))
        self.ui_droparea.setProperty("curr_img", self.current_img + 1)
        self.execute_load()

    @Slot(bool, name="next_img")
    def next_img(self, up: bool):
        """ Steps to the next image on mousewheel event

        Parameters:
            up (bool): True if mousewheel moves up

        """
        if len(self.url_list):
            self.current_img += 1 if up else -1
            self.current_img %= len(self.url_list)
            self.execute_load()

    @Slot(int, name="channel_change")
    def channel_change(self, channel: int):
        """ Called when channel is selected in the thumbnails bar

        Parameters:
            channel (int): Index of the selected channel

        """
        global im
        im = self.img_instances[int(channel)]
        self.update_displays()

    @Slot(str, name="save_img")
    def save_img(self, path):
        """Saves the visible kspace and image to files

        Saves the 32 bit/pixel image if TIFF format is selected otherwise
        the PNG file will have a depth of 8 bits.

        Parameters:
            path (str): QUrl format file location (starts with "file:///")
        """
        import os.path
        filename, ext = os.path.splitext(path[8:])  # Remove QUrl's "file:///"
        k_path = filename + '_k' + ext
        i_path = filename + '_i' + ext
        if ext.lower() == '.tiff':
            Image.fromarray(im.img).save(i_path)
            Image.fromarray(im.kspace_display_data).save(k_path)
        elif ext == '.png':
            Image.fromarray(im.img).convert(mode='L').save(i_path)
            Image.fromarray(im.kspace_display_data).convert(mode='L').save(
                k_path)
        elif ext == '.npy':
            np.save(i_path, im.img)
            np.save(k_path, im.kspacedata)

    @Slot(float, float, name="add_spike")
    def add_spike(self, mouse_x, mouse_y):
        """Inserts a spike at a location given by the UI.

        Values are saved in reverse order because NumPy's indexing conventions:
        array[row (== y), column (== x)]

        Parameters:
            mouse_x: click position on the x-axis
            mouse_y: click position on the y-axis
        """
        im.spikes.append((int(mouse_y), int(mouse_x)))

    @Slot(float, float, float, name="add_patch")
    def add_patch(self, mouse_x, mouse_y, radius):
        """Inserts a patch at a location given by the UI.

        Values are saved in reverse order because NumPy's indexing conventions:
        array[row (== y), column (== x)]

        Parameters:
            mouse_x: click position on the x-axis
            mouse_y: click position on the y-axis
            radius: size of the patch
        """
        im.patches.append((int(mouse_y), int(mouse_x), int(radius)))

    @Slot(name="delete_spikes")
    def delete_spikes(self):
        """Deletes manually added kspace spikes"""
        im.spikes = []

    @Slot(name="delete_patches")
    def delete_patches(self):
        """Deletes manually added kspace patches"""
        im.patches = []

    @Slot(name="undo_patch")
    def undo_patch(self):
        """Deletes the last patch"""
        if im.patches:
            del im.patches[-1]

    @Slot(name="undo_spike")
    def undo_spike(self):
        """Deletes the last spike"""
        if im.spikes:
            del im.spikes[-1]

    @Slot(name="update_displays")
    def update_displays(self):
        """Triggers modifiers to kspace and updates the displays"""
        self.image_change()

        # Replacing image source for QML Image elements - this will trigger
        # requestPixmap. The image name must be different for Qt to display the
        # new one, so a random string is appended to the end
        self.ui_kspace_display. \
            setProperty("source", "image://imgs/kspace_%s" % uuid4().hex)
        self.ui_image_display. \
            setProperty("source", "image://imgs/image_%s" % uuid4().hex)

        #  Iterate through thumbnails and set source image to trigger reload
        for item in self.ui_thumbnails.childItems()[0].childItems():
            try:
                oname = item.childItems()[0].property("objectName")
                source = "image://imgs/" + oname + "_%s" % uuid4().hex
                item.childItems()[0].setProperty("source", source)
            except IndexError:
                # Highlight component of the ListView does not have childItems
                pass

    def image_change(self):
        """ Apply kspace modifiers to kspace and get resulting image"""

        # Get a copy of the original k-space data to play with
        im.resize_arrays(im.orig_kspacedata.shape)
        im.kspacedata[:] = im.orig_kspacedata

        # 01 - Noise
        new_snr = self.ui_noise_slider.property('value')
        generate_new = False
        if new_snr != im.signal_to_noise:
            generate_new = True
            im.signal_to_noise = new_snr
        im.add_noise(im.kspacedata, new_snr, im.noise_map, generate_new)

        # 02 - Spikes
        im.apply_spikes(im.kspacedata, im.spikes)

        # 03 - Patches
        im.apply_patches(im.kspacedata, im.patches)

        # 04 - Reduced scan percentage
        if self.ui_rdc_slider.property("enabled"):
            v_ = self.ui_rdc_slider.property("value")
            im.reduced_scan_percentage(im.kspacedata, v_)

        # 05 - Partial fourier
        if self.ui_partial_fourier_slider.property("enabled"):
            v_ = self.ui_partial_fourier_slider.property("value")
            zf = self.ui_zero_fill.property("checked")
            im.partial_fourier(im.kspacedata, v_, zf)

        # 06 - High pass filter
        v_ = self.ui_high_pass_slider.property("value")
        im.high_pass_filter(im.kspacedata, v_)

        # 07 - Low pass filter
        v_ = self.ui_low_pass_slider.property("value")
        im.low_pass_filter(im.kspacedata, v_)

        # 08 - Undersample k-space
        v_ = self.ui_undersample_kspace.property("value")
        if int(v_):
            compress = self.ui_compress.property("checked")
            im.undersample(im.kspacedata, int(v_), compress)

        # 09 - DC signal decrease
        v_ = self.ui_decrease_dc.property("value")
        if int(v_) > 1:
            im.decrease_dc(im.kspacedata, int(v_))

        # 10 - Hamming filter
        if self.ui_hamming.property("checked"):
            im.hamming(im.kspacedata)

        # 11 - Acquisition simulation progress
        if self.ui_filling.property("value") < 100:
            mode = self.ui_filling_mode.property("currentIndex")
            im.filling(im.kspacedata, self.ui_filling.property("value"), mode)

        # Get the resulting image
        im.np_ifft(kspace=im.kspacedata, out=im.img)

        # Get display properties
        kspace_const = int(self.ui_ksp_const.property('value'))
        # Window values
        ww = self.ui_image_display.property("ww")
        wc = self.ui_image_display.property("wc")
        win_val = {'ww': ww, 'wc': wc}
        im.prepare_displays(kspace_const, win_val)


class ImageProvider(QtQuick.QQuickImageProvider):
    """
    Contains the interface between numpy and Qt.
    Qt calls MainApp.update_displays on UI change
    that method requests new images to display
    pyqt channels it back to Qt GUI

    """

    def __init__(self):
        QtQuick.QQuickImageProvider. \
            __init__(self, QtQuick.QQuickImageProvider.Pixmap)

    def requestPixmap(self, id_str: str, size, requested_size):
        """Qt calls this function when an image changes

        Parameters:
            id_str: identifies the requested image
            size: This is used to set the width and height of the relevant Image.
            requested_size: image size requested by QML (usually ignored)

        Returns:
            QPixmap: an image in the format required by Qt
        """


        try:
            if id_str.startswith('image'):
                q_im = QImage(im.image_display_data,             # data
                              im.image_display_data.shape[1],    # width
                              im.image_display_data.shape[0],    # height
                              im.image_display_data.strides[0],  # bytes/line
                              QImage.Format_Grayscale8)          # format

            elif id_str.startswith('kspace'):
                q_im = QImage(im.kspace_display_data,             # data
                              im.kspace_display_data.shape[1],    # width
                              im.kspace_display_data.shape[0],    # height
                              im.kspace_display_data.strides[0],  # bytes/line
                              QImage.Format_Grayscale8)           # format

            elif id_str.startswith('thumb'):
                thumb_id = int(id_str[6:6+id_str[6:].find('_')])
                im_c = py_mainapp.img_instances[thumb_id]
                q_im = QImage(im_c.image_display_data,             # data
                              im_c.image_display_data.shape[1],    # width
                              im_c.image_display_data.shape[0],    # height
                              im_c.image_display_data.strides[0],  # bytes/line
                              QImage.Format_Grayscale8)            # format

            else:
                raise NameError

        except NameError:
            print(NameError)
            # On error, we return a red image of requested size
            q_im = QPixmap(requested_size)
            q_im.fill(QColor('red'))

        return QPixmap(q_im)#, QPixmap(q_im).size()


# Define im global
default_image = 'data/default.dcm'
app_path = pathlib.Path(__file__).parent.absolute()
default_image = str(app_path.joinpath(default_image))
im = ImageManipulators(open_file(default_image), is_image=True)


class SimulationView(QQmlApplicationEngine):

    def __init__(self,  parent=None):
        # Call super class
        super(SimulationView, self).__init__(parent)

        # Image manipulator and storage initialisation with default image
        self.addImageProvider("imgs", ImageProvider())

        # Expose the ... to the QML code
        # self.rootContext().setContextProperty("", self.)

        # Connects here

        # Load the QML file
        qml_file = os.path.join(os.path.dirname(__file__), "views/view.qml")
        self.load(qml_file)
        if not self.rootObjects():
            sys.exit(-1)

        # TBD refactor MainApp out
        ctx = self.rootContext()
        self.win = self.rootObjects()[0]
        self._mainapp = MainApp(ctx, self.win)

        ctx.setContextProperty("py_MainApp", self._mainapp)

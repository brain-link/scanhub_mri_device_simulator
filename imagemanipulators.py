#!/usr/bin/env python
# -*- conding: utf-8 -*-
import os
import pathlib
import sys
import numpy as np

# Attempting to use mkl_fft (faster FFT library for Intel CPUs). Fallback is np
try:
    import mkl_fft as m

    fft2 = m.fft2
    ifft2 = m.ifft2
except (ModuleNotFoundError, ImportError):
    fft2 = np.fft.fft2
    ifft2 = np.fft.ifft2
finally:
    fftshift = np.fft.fftshift
    ifftshift = np.fft.ifftshift

class ImageManipulators:
    """A class that contains a 2D image and kspace pair and modifier methods

    This class will load the specified image or raw data and performs any
    actions that modify the image or kspace data. A new instance should be
    initialized for new images.
    """

    def __init__(self, pixel_data: np.ndarray, is_image: bool = True):
        """Opening the image and initializing variables based on image size

        Parameters:
            pixel_data (np.ndarray): 2D pixel data of image or kspace
            is_image (bool): True if the data is an Image, false if raw data
        """

        if is_image:
            self.img = pixel_data.copy()
            self.kspacedata = np.zeros_like(self.img, dtype=np.complex64)
        else:
            self.kspacedata = pixel_data.copy()
            self.img = np.zeros_like(self.kspacedata, dtype=np.float32)

        self.image_display_data = np.require(self.img, np.uint8, 'C')
        self.kspace_display_data = np.zeros_like(self.image_display_data)
        self.orig_kspacedata = np.zeros_like(self.kspacedata)
        self.kspace_abs = np.zeros_like(self.kspacedata, dtype=np.float32)
        self.noise_map = np.zeros_like(self.kspace_abs)
        self.signal_to_noise = 30
        self.spikes = []
        self.patches = []

        if is_image:
            self.np_fft(self.img, self.kspacedata)
        else:
            self.np_ifft(self.kspacedata, self.img)

        self.orig_kspacedata[:] = self.kspacedata  # Store data write-protected
        self.orig_kspacedata.setflags(write=False)

        self.prepare_displays()

    @staticmethod
    def np_ifft(kspace: np.ndarray, out: np.ndarray):
        """Performs inverse FFT function (kspace to [magnitude] image)

        Performs iFFT on the input data and updates the display variables for
        the image domain (magnitude) image and the kspace as well.

        Parameters:
            kspace (np.ndarray): Complex kspace ndarray
            out (np.ndarray): Array to store values
        """
        np.absolute(fftshift(ifft2(ifftshift(kspace))), out=out)

    @staticmethod
    def np_fft(img: np.ndarray, out: np.ndarray):
        """ Performs FFT function (image to kspace)

        Performs FFT function, FFT shift and stores the unmodified kspace data
        in a variable and also saves one copy for display and edit purposes.

        Parameters:
            img (np.ndarray): The NumPy ndarray to be transformed
            out (np.ndarray): Array to store output (must be same shape as img)
        """
        out[:] = fftshift(fft2(ifftshift(img)))

    @staticmethod
    def normalise(f: np.ndarray):
        """ Normalises array by "streching" all values to be between 0-255.

        Parameters:
            f (np.ndarray): input array
        """
        fmin = float(np.min(f))
        fmax = float(np.max(f))
        if fmax != fmin:
            coeff = fmax - fmin
            f[:] = np.floor((f[:] - fmin) / coeff * 255.)

    @staticmethod
    def apply_window(f: np.ndarray, window_val: dict = None):
        """ Applies window values to the array

        Excludes certain values based on window width and center before
        applying normalisation on array f.
        Window values are interpreted as percentages of the maximum
        intensity of the actual image.
        For example if window_val is 1, 0.5 and image has maximum intensity
        of 196 then window width is 196, window center is 98.
        Code applied from contrib-pydicom see license below:
            Copyright (c) 2009 Darcy Mason, Adit Panchal
            This file is part of pydicom, relased under an MIT license.
            See the file LICENSE included with this distribution, also
            available at https://github.com/pydicom/pydicom
            Based on image.py from pydicom version 0.9.3,
            LUT code added by Adit Panchal

        Parameters:
            f (np.ndarray): the array to be windowed
            window_val (dict): window width and window center dict
        """
        fmax = np.max(f)
        fmin = np.min(f)
        if fmax != fmin:
            ww = (window_val['ww'] * fmax) if window_val else fmax
            wc = (window_val['wc'] * fmax) if window_val else (ww / 2)
            w_low = wc - ww / 2
            w_high = wc + ww / 2
            f[:] = np.piecewise(f, [f <= w_low, f > w_high], [0, 255,
                                lambda x: ((x - wc) / ww + 0.5) * 255])

    def prepare_displays(self, kscale: int = -3, lut: dict = None):
        """ Prepares kspace and image for display in the user interface

        Magnitude of the kspace is taken and scaling is applied for display
        purposes. This scaled representation is then transformed to a 256 color
        grayscale image by normalisation (where the highest and lowest
        intensity pixels will be intensity level 255 and 0 respectively)
        Similarly the image is prepared with the addition of windowing
        (excluding certain values based on user preference before normalisation
        e.g. intensity lower than 20 and higher than 200).

        Parameters:
            kscale (int): kspace intensity scaling constant (10^kscale)
            lut (dict): window width and window center dict
        """

        # 1. Apply window to image
        self.apply_window(self.img, lut)

        # 2. Prepare kspace display - get magnitude then scale and normalise
        # K-space scaling: https://homepages.inf.ed.ac.uk/rbf/HIPR2/pixlog.htm
        np.absolute(self.kspacedata, out=self.kspace_abs)
        if np.any(self.kspace_abs):
            scaling_c = np.power(10., kscale)
            np.log1p(self.kspace_abs * scaling_c, out=self.kspace_abs)
            self.normalise(self.kspace_abs)

        # 3. Obtain uint8 type arrays for QML display
        self.image_display_data[:] = np.require(self.img, np.uint8)
        self.kspace_display_data[:] = np.require(self.kspace_abs, np.uint8)

    def resize_arrays(self, size: (int, int)):
        """ Resize arrays for image size changes (e.g. remove kspace lines etc.)

        Called by undersampling kspace and the image_change method. If the FOV
        is modified, image_change will reset the size based on the original
        kspace, performs other modifications to the image that are applied
        before undersampling and then reapplies the size change.

        Parameters:
            size (int, int): size of the new array
        """
        self.img.resize(size)
        self.image_display_data.resize(size)
        self.kspace_display_data.resize(size)
        self.kspace_abs.resize(size)
        self.kspacedata.resize(size, refcheck=False)

    @staticmethod
    def reduced_scan_percentage(kspace: np.ndarray, percentage: float):
        """Deletes a percentage of lines from the kspace in phase direction

        Deletes an equal number of lines from the top and bottom of kspace
        to only keep the specified percentage of sampled lines. For example if
        the image has 256 lines and percentage is 50.0 then 64 lines will be
        deleted from the top and bottom and 128 will be kept in the middle.

        Parameters:
            kspace (np.ndarray): Complex kspace data
            percentage (float): The percentage of lines sampled (0.0 - 100.0)
        """

        if int(percentage) < 100:
            percentage_delete = 1 - percentage / 100
            lines_to_delete = round(percentage_delete * kspace.shape[0] / 2)
            if lines_to_delete:
                kspace[0:lines_to_delete] = 0
                kspace[-lines_to_delete:] = 0

    @staticmethod
    def high_pass_filter(kspace: np.ndarray, radius: float):
        """High pass filter removes the low spatial frequencies from k-space

        This function deletes the center of kspace by removing values
        inside a circle of given size. The circle's radius is determined by
        the 'radius' float variable (0.0 - 100) as ratio of the lenght of
        the image diagonally.

        Parameters:
            kspace (np.ndarray): Complex kspace data
            radius (float): Relative size of the kspace mask circle (percent)
        """

        if radius > 0:
            r = np.hypot(*kspace.shape) / 2 * radius / 100
            rows, cols = np.array(kspace.shape, dtype=int)
            a, b = np.floor(np.array((rows, cols)) / 2).astype(int)
            y, x = np.ogrid[-a:rows - a, -b:cols - b]
            mask = x * x + y * y <= r * r
            kspace[mask] = 0

    @staticmethod
    def low_pass_filter(kspace: np.ndarray, radius: float):
        """Low pass filter removes the high spatial frequencies from k-space

        This function only keeps the center of kspace by removing values
        outside a circle of given size. The circle's radius is determined by
        the 'radius' float variable (0.0 - 100) as ratio of the lenght of
        the image diagonally

        Parameters:
            kspace (np.ndarray): Complex kspace data
            radius (float): Relative size of the kspace mask circle (percent)
        """

        if radius < 100:
            r = np.hypot(*kspace.shape) / 2 * radius / 100
            rows, cols = np.array(kspace.shape, dtype=int)
            a, b = np.floor(np.array((rows, cols)) / 2).astype(int)
            y, x = np.ogrid[-a:rows - a, -b:cols - b]
            mask = x * x + y * y <= r * r
            kspace[~mask] = 0

    @staticmethod
    def add_noise(kspace: np.ndarray, signal_to_noise: float,
                  current_noise: np.ndarray, generate_new_noise=False):
        """Adds random Guassian white noise to k-space

        Adds noise to the image to simulate an image with the given
        signal-to-noise ratio, so that SNR [dB] = 20log10(S/N)
        where S is the mean signal and N is the standard deviation of the noise.

        Parameters:
            kspace (np.ndarray): Complex kspace ndarray
            signal_to_noise (float): SNR in decibels (-30dB - +30dB)
            current_noise (np.ndarray): the existing noise map
            generate_new_noise (bool): flag to generate new noise map
        """

        if signal_to_noise < 30:
            if generate_new_noise:
                mean_signal = np.mean(np.abs(kspace))
                std_noise = mean_signal / np.power(10, (signal_to_noise / 20))
                current_noise[:] = std_noise * np.random.randn(*kspace.shape)
            kspace += current_noise

    @staticmethod
    def partial_fourier(kspace: np.ndarray, percentage: float, zf: bool):
        """ Partial Fourier

        Also known as half scan - only acquire a little over half of k-space
        or more and use conjugate symmetry to fill the rest.

        Parameters:
            kspace (np.ndarray): Complex k-space
            percentage (float): Sampled k-space percentage
            zf (bool): Zero-fill k-space instead of using symmetry
        """

        if int(percentage) != 100:
            percentage = 1 - percentage / 100
            rows_to_skip = round(percentage * (kspace.shape[0] / 2 - 1))
            if rows_to_skip and zf:
                # Partial Fourier (lines not acquired are filled with zeros)
                kspace[-rows_to_skip:] = 0
            elif rows_to_skip:
                # If the kspace has an even resolution then the
                # mirrored part will be shifted (k-space center signal
                # (DC signal) is off center). This determines the peak
                # position and adjusts the mirrored quadrants accordingly
                # https://www.ncbi.nlm.nih.gov/pubmed/22987283

                # Following two lines are a connoisseur's (== obscure) way of
                # returning 1 if the number is even and 0 otherwise. Enjoy!
                shift_hor = not kspace.shape[1] & 0x1  # Bitwise AND
                shift_ver = 0 if kspace.shape[0] % 2 else 1  # Ternary operator
                s = (shift_ver, shift_hor)

                # 1. Obtain a view of the array backwards (rotated 180 degrees)
                # 2. If the peak is off center horizontally (e.g. number of
                #       columns or rows is even) roll lines to realign the
                #       highest amplitude parts
                # 3. Do the same vertically
                kspace[-rows_to_skip:] = \
                    np.roll(kspace[::-1, ::-1], s, axis=(0, 1))[-rows_to_skip:]

                # Conjugate replaced lines
                np.conj(kspace[-rows_to_skip:], kspace[-rows_to_skip:])

    @staticmethod
    def hamming(kspace: np.ndarray):
        """ Hamming filter

        Applies a 2D Hamming filter to reduce Gibbs ringing
        References:
            https://mriquestions.com/gibbs-artifact.html
            https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4058219/
            https://www.roberthovden.com/tutorial/2015/fftartifacts.html

        Parameters:
            kspace: Complex k-space numpy.ndarray
        """
        x, y = kspace.shape
        window = np.outer(np.hamming(x), np.hamming(y))
        kspace *= window

    def undersample(self, kspace: np.ndarray, factor: int, compress: bool):
        """ Skipping every nth kspace line

        Simulates acquiring every nth (where n is the acceleration factor) line
        of kspace, starting from the midline. Commonly used in SENSE algorithm.

        Parameters:
            kspace: Complex k-space numpy.ndarray
            factor: Only scan every nth line (n=factor) starting from midline
            compress: compress kspace by removing empty lines (rectangular FOV)
        """
        # TODO memory optimise this (kspace sized memory created 3 times)
        if factor > 1:
            mask = np.ones(kspace.shape, dtype=bool)
            midline = kspace.shape[0] // 2
            mask[midline::factor] = 0
            mask[midline::-factor] = 0
            if compress:
                q = kspace[~mask]
                q = q.reshape(q.size // kspace.shape[1], kspace.shape[1])
                self.resize_arrays(q.shape)
                kspace[:] = q[:]
            else:
                kspace[mask] = 0

    @staticmethod
    def decrease_dc(kspace: np.ndarray, percentage: int):
        """Decreases the highest peak in kspace (DC signal)

        Parameters:
            kspace: Complex k-space numpy.ndarray
            percentage: reduce the DC value by this value
        """
        x = kspace.shape[0] // 2
        y = kspace.shape[1] // 2
        kspace[x, y] *= (100 - percentage) / 100

    @staticmethod
    def apply_spikes(kspace: np.ndarray, spikes: list):
        """Overlays spikes to kspace

        Apply spikes (max value pixels) to the kspace data at the specified
        coordinates.

        Parameters:
            kspace (np.ndarray): Complex kspace ndarray
            spikes (list): coordinates for the spikes (row, column)
        """
        spike_intensity = np.max(kspace) * 2
        for spike in spikes:
            kspace[spike] = spike_intensity

    @staticmethod
    def apply_patches(kspace, patches: list):
        """Applies patches to kspace

         Apply patches (zero value squares) to the kspace data at the
         specified coordinates and size.

         Parameters:
             kspace (np.ndarray): Complex kspace ndarray
             patches (list): coordinates for the spikes (row, column, radius)
         """
        for patch in patches:
            x, y, size = patch[0], patch[1], patch[2]
            kspace[max(x - size, 0):x + size + 1,
                   max(y - size, 0):y + size + 1] = 0

    @staticmethod
    def filling(kspace: np.ndarray, value: float, mode: int):
        """Receives kspace filling UI changes and redirects to filling methods

        When the kspace filling simulation slider changes or simulation plays,
        this method receives the acquision phase (value: float, 0-100%)

        Parameters:
            kspace (np.ndarray): Complex kspace ndarray
            value (float): acquisition phase in percent
            mode (int): kspace filling mode
        """
        if mode == 0:  # Linear filling
            ImageManipulators.filling_linear(kspace, value)
        elif mode == 1:  # Centric filling
            ImageManipulators.filling_centric(kspace, value)
        elif mode == 2:  # Single shot EPI blipped
            ImageManipulators.filling_ss_epi_blipped(kspace, value)
        elif mode == 3:  # Archimedean spiral
            # filling_spiral(kspace, value)
            pass

    @staticmethod
    def filling_linear(kspace: np.ndarray, value: float):
        """Linear kspace filling

        Starts with the top left corner and sequentially fills kspace from
        top to bottom
        Parameters:
            kspace (np.ndarray): Complex kspace ndarray
            value (float): acquisition phase in percent
        """
        kspace.flat[int(kspace.size * value // 100)::] = 0

    @staticmethod
    def filling_centric(kspace: np.ndarray, value: float):
        """ Centric filling method

        Fills the center line first from left to right and then alternating one
        line above and one below.
        """
        ksp_centric = np.zeros_like(kspace)

        # reorder
        ksp_centric[0::2] = kspace[kspace.shape[0] // 2::]
        ksp_centric[1::2] = kspace[kspace.shape[0] // 2 - 1::-1]

        ksp_centric.flat[int(kspace.size * value / 100)::] = 0

        # original order
        kspace[(kspace.shape[0]) // 2 - 1::-1] = ksp_centric[1::2]
        kspace[(kspace.shape[0]) // 2::] = ksp_centric[0::2]

    @staticmethod
    def filling_ss_epi_blipped(kspace: np.ndarray, value: float):
        # Single-shot blipped EPI (zig-zag pattern)
        # https://www.imaios.com/en/e-Courses/e-MRI/MRI-Sequences/echo-planar-imaging
        ksp_epi = np.zeros_like(kspace)
        ksp_epi[::2] = kspace[::2]
        ksp_epi[1::2] = kspace[1::2, ::-1]  # Every second line backwards

        ksp_epi.flat[int(kspace.size * value / 100)::] = 0

        kspace[::2] = ksp_epi[::2]
        kspace[1::2] = ksp_epi[1::2, ::-1]

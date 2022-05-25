scanhub-mri-device-simulator
============================

.. code-block:: bash

    python main.py --log

Trigger Measurement via `ScanHub <https://github.com/brain-link/scanhub_new>`_ Debug Workflow:

.. code-block:: bash

    http://localhost:81/api/TriggerAcquisition?cmd=MEAS_START


Installation
============

.. code-block:: bash

    pip install virtualenv

    python -m virtualenv .env

    .\.env\Scripts\activate

    pip install -r requirements.txt


References
==========

Inspired by the `K-space Explorer <https://github.com/birogeri/kspace-explorer>`_ project.


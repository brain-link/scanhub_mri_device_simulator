scanhub-mri-device-simulator
============================

.. code-block:: bash

    python main.py --log

Trigger Measurement via Debug Workflow:

.. code-block:: bash

    http://localhost:81/api/TriggerAcquisition?cmd=MEAS_START


development
===========

pip install virtualenv
python -m virtualenv .env

.\.env\Scripts\activate
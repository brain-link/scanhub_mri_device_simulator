ScanHub MRI Device Simulator
----------------------------

<p align="center">
<a href="https://github.com/brain-link/scanhub_mri_device_simulator/actions/workflows/static-tests.yml" target="_blank">
    <img src="https://github.com/brain-link/scanhub_mri_device_simulator/actions/workflows/static-tests.yml/badge.svg" alt="Static Tests"/>
</a>
</p>

ScanHub MRI Device Simulator is a Python package for simulating MRI devices. It is part of the ScanHub project.

.. code-block:: bash

    python main.py --log

Trigger Measurement via `ScanHub <https://github.com/brain-link/scanhub_new>`_ Debug Workflow:

.. code-block:: bash

    http://localhost:8080/api/v1/mri/acquisitioncontrol/docs


Installation
------------

.. code-block:: bash

    pip install virtualenv

    python -m virtualenv .env

    .\.env\Scripts\activate

    poetry install


References
----------

Inspired by the `K-space Explorer <https://github.com/birogeri/kspace-explorer>`_ project.


Open Points
-----------

- Integrate Bloch Simulator for sequence simulation

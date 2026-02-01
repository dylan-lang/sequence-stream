***************************
The SEQUENCE-STREAM library
***************************

.. current-library:: sequence-stream


The SEQUENCE-STREAM module
**************************

.. current-module:: sequence-stream


.. class:: <byte-string-stream>
   :primary:

   :superclasses: :class:`<string-stream>`

   :keyword contents: An instance of :drm:`<object>`.
   :keyword element-type: An instance of :drm:`<object>`.
   :keyword fill: An instance of :drm:`<object>`.

.. class:: <sequence-stream>
   :open:
   :primary:

   :superclasses: :class:`<basic-stream>`, :class:`<positionable-stream>`

   :keyword contents: An instance of :class:`<sequence>`.
   :keyword direction: An instance of ``one-of(#"input", #"output", #"input-output")``.
   :keyword element-type: An instance of :class:`<type>`.
   :keyword end: An instance of :class:`<integer>`.
   :keyword fill: An instance of :class:`<object>`.
   :keyword outer-stream: An instance of :drm:`<object>`.
   :keyword position-offset: An instance of :class:`<integer>`.
   :keyword start: An instance of :class:`<integer>`.

.. class:: <string-stream>
   :open:
   :primary:

   :superclasses: :class:`<sequence-stream>`

   :keyword contents: An instance of :drm:`<object>`.
   :keyword element-type: An instance of :drm:`<object>`.
   :keyword fill: An instance of :drm:`<object>`.

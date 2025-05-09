# Safe-start ProGuard rules for LinguaVisual

# Keep model classes used for JSON parsing
-keep class com.iacstudio.languador.model.** { *; }

# Retain annotation attributes (e.g., Kotlin, JSON)
-keepattributes *Annotation*

# Controlio

Transport: MultipeerConnectivity
- iOS browses, macOS advertises
- serviceType = "controlio-trk"

Event schema (JSON, line-delimited):
- {"t":"pm","p":{"dx":Int,"dy":Int}} pointer move
- {"t":"bt","p":{"c":Int /*0=left,1=right*/,"s":Int /*0=up,1=down*/}} button
- {"t":"sc","p":{"dx":Int,"dy":Int}} scroll
- (reserve {"t":"gs","p":{"k":Int,"v":Int}} for gestures later)

XCBGEN(XCB_DPMS)
_H`'INCHEADERS(INCHERE(xp_core.h))
_C`'INCHEADERS(INCHERE(xcb_dpms.h))

BEGINEXTENSION(DPMS, DPMS)

REQUEST(DPMSGetVersion, `
    OPCODE(0)
    PARAM(CARD16, `client_major_version')
    PARAM(CARD16, `client_minor_version')
', `
    PAD(1)
    REPLY(CARD16, `server_major_version')
    REPLY(CARD16, `server_minor_version')
')

REQUEST(DPMSCapable, `
    OPCODE(1)
', `
    PAD(1)
    REPLY(BOOL, `capable')
')

REQUEST(DPMSGetTimeouts, `
    OPCODE(2)
', `
    PAD(1)
    REPLY(CARD16, `standby_timeout')
    REPLY(CARD16, `suspend_timeout')
    REPLY(CARD16, `off_timeout')
')

VOIDREQUEST(DPMSSetTimeouts, `
    OPCODE(3)
    PARAM(CARD16, `standby_timeout')
    PARAM(CARD16, `suspend_timeout')
    PARAM(CARD16, `off_timeout')
')

VOIDREQUEST(DPMSEnable, `
    OPCODE(4)
')

VOIDREQUEST(DPMSDisable, `
    OPCODE(5)
')

VOIDREQUEST(DPMSForceLevel, `
    OPCODE(6)
    PARAM(CARD16, `power_level')
')

REQUEST(DPMSInfo, `
    OPCODE(7)
', `
    PAD(1)
    REPLY(CARD16, `power_level')
    REPLY(BOOL, `state')
')
ENDEXTENSION
ENDXCBGEN

#include "xcb_reply.h"

#include <stdio.h>
#include <stdlib.h>

void fontinfo_handler(void *data, XCBConnection *c, XCBGenericRep *rg, XCBGenericError *eg)
{
	XCBListFontsWithInfoRep *rep = (XCBListFontsWithInfoRep *) rg;
	if(rep)
	{
		if(rep->name_len)
			printf("Font %*s (%u remain)\n", rep->name_len, XCBListFontsWithInfoName(rep), (unsigned int) rep->replies_hint);
		else
			printf("End of font list.\n");
	}
	if(eg)
		printf("Error from ListFontsWithInfo: %d\n", eg->error_code);
}

int main(void)
{
	XCBConnection *c = XCBConnectBasic();
	ReplyHandlers *h = allocReplyHandlers(c);
	pthread_t reply_thread;
	
	AddReplyHandler(h, XCBListFontsWithInfo(c, 10, 1, "*").sequence, fontinfo_handler, 0);
	reply_thread = StartReplyThread(h);

	XCBSync(c, 0);
	StopReplyThreads(h);
	pthread_join(reply_thread, 0);
	XCBDisconnect(c);
	exit(0);
}

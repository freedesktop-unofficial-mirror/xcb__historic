#include "xclint.h"

int XFree(void *p)
{
	Xfree(p);
	return 1;
}

int _XFreeExtData(XExtData *extension)
{
	XExtData *temp;
	while (extension) {
		if (extension->free_private) 
		    (*extension->free_private)(extension);
		else Xfree ((char *)extension->private_data);
		temp = extension->next;
		Xfree ((char *)extension);
		extension = temp;
	}
	return 0;
}

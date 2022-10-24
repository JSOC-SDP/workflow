# Standard things
sp 		:= $(sp).x
dirstack_$(sp)	:= $(d)
d		:= $(dir)

# Subdirectories. Directory-specific rules are optional here. The
# order DOES matter, always define libraries before applications
# that use those libraries.
dir		:= $(d)/apps
-include	$(SRCDIR)/$(dir)/Rules.mk

.PHONY:		workflow_
workflow_:	workflow_apps

# Standard things
d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))

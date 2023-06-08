# Standard things
sp 							:= $(sp).x
dirstack_$(sp)	:= $(d)
d								:= $(dir)

PROJECT_$(d)	:= $(call GET_PROJECT,$(d))

# Subdirectories. Directory-specific rules are optional here. The
# order DOES matter, always define libraries before applications
# that use those libraries.
dir		:= $(d)/apps
-include	$(SRCDIR)/$(dir)/Rules.mk

.PHONY:		$(PROJECT_$(d))_all
$(PROJECT_$(d))_all::		;

universe::					$(PROJECT_$(d))_all

# Standard things
d		:= $(dirstack_$(sp))
sp	:= $(basename $(sp))

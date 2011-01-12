# Standard things
sp 		:= $(sp).x
dirstack_$(sp)	:= $(d)
d		:= $(dir)

# Local variables
CEXE_$(d)       := $(addprefix $(d)/, GetNextID )
CEXE            := $(CEXE) $(CEXE_$(d))

EXE_$(d)	:= $(CEXE_$(d))
OBJ_$(d)	:= $(EXE_$(d):%=%.o) 
DEP_$(d)	:= $(OBJ_$(d):%=%.d)
CLEAN		:= $(CLEAN) \
		   $(OBJ_$(d)) \
		   $(EXE_$(d)) \
		   $(DEP_$(d))

S_$(d)		:= $(notdir $(EXE_$(d)) )

# Local rules
$(OBJ_$(d)):		$(SRCDIR)/$(d)/Rules.mk

# NOTE: Add dependent libraries with the -I compiler flag, and make the module depend
#   on that library

# Shortcuts
.PHONY:	$(S_$(d))
$(S_$(d)):	%:	$(d)/%

# Standard things
-include	$(DEP_$(d))

d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))

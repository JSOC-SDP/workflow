# Standard things
sp				:= $(sp).x
dirstack_$(sp)	:= $(d)
d				:= $(dir)

# Local variables
PROJECT_$(d)					:= $(call GET_PROJECT,$(d))
CEXE_$(d)						:= $(addprefix $(d)/, GetNextID)
APPLICATIONS_$(d)				:= $(CEXE_$(d))
APPLICATION_TARGETS_$(d)		:= $(foreach application,$(notdir $(APPLICATIONS_$(d))),$(PROJECT_$(d))_$(application))

.PHONY:	$(APPLICATION_TARGETS_$(d))
$(call MAKE_BUILT_APPLICATION_PREREQS,$(APPLICATION_TARGETS_$(d)))

$(PROJECT_$(d))_all::			   $(APPLICATION_TARGETS_$(d))

PROJ_CEXE						:= $(PROJ_CEXE) $(CEXE_$(d))

OBJ_$(d)						:= $(APPLICATIONS_$(d):%=%.o) 
DEP_$(d)						:= $(OBJ_$(d):%=%.d)
CLEAN							:= $(CLEAN) \
								   $(OBJ_$(d)) \
								   $(APPLICATIONS_$(d)) \
								   $(DEP_$(d))

S_$(d)							:= $(notdir $(APPLICATIONS_$(d)))
TGT_BIN							:= $(TGT_BIN) $(APPLICATIONS_$(d))

# exe/lib-specific
BUILD_DEPENDENCIES_$(d)			:=
HEADER_DEPENDENCIES_$(d)		:=
DEPENDENCY_LIST_$(d)			:= $(BUILD_DEPENDENCIES_$(d)) $(HEADER_DEPENDENCIES_$(d))
LINK_LIBS_FLAGS_$(d)			:= $(call GEN_LINK_LIBS_FLAGS,$(BUILD_DEPENDENCIES_$(d)))
INCS_FLAGS_$(d)					:= $(call GEN_INC_FLAGS,$(DEPENDENCY_LIST_$(d)))
HEADER_PREREQS_$(d)				:= $(call GEN_HEADER_PREREQS,$(DEPENDENCY_LIST_$(d)))
DEPENDENCY_PREREQS_$(d)			:= $(call GEN_DEPENDENCY_PREREQS,$(BUILD_DEPENDENCIES_$(d)))

# Local rules
$(OBJ_$(d)):					   $(SRCDIR)/$(d)/Rules.mk $(HEADER_PREREQS_$(d))
$(OBJ_$(d)):					   CF_TGT := $(CF_TGT) $(INCS_FLAGS_$(d)) -I$(SRCDIR)/$(d)/src/

$(APPLICATIONS_$(d)):			   LL_TGT := $(LL_TGT) $(LINK_LIBS_FLAGS_$(d))
$(APPLICATIONS_$(d)):			   PREREQS := $(PREREQS) $(DEPENDENCY_PREREQS_$(d))
$(APPLICATIONS_$(d)):			   $(DEPENDENCY_PREREQS_$(d))

# Shortcuts
.PHONY:		$(S_$(d))
$(S_$(d)):	%:	$(d)/%

# Standard things
-include	$(DEP_$(d))

d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))


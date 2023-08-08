# this file contains make info needed by the Rules.mk of base and/or other projects; it cannot go in Rules.mk,
# which gets included in tree-traversal order (so a Rules.mk needed by a second Rules.mk might not yet
# be included)

# apps
$(call REGISTER_APPLICATION,$(PROJECT),GetNextID,$(PROJECT)/apps/GetNextID)

$(call REGISTER_SCRIPTS,$(PROJECT),workflow,../$(PROJECT)/scripts)

$(call REGISTER_SOURCE,$(PROJECT),$(PROJECT),$(PROJECT))

$(eval $(call register_installation,$(PROJECT)))

INSTALL_BINS_CMD_$(PROJECT) := $(INSTALL_BINS_CMD_$(PROJECT))
INSTALL_INCS_CMD_$(PROJECT) := $(INSTALL_INCS_CMD_$(PROJECT))
INSTALL_LIBS_CMD_$(PROJECT) := $(INSTALL_LIBS_CMD_$(PROJECT))
INSTALL_LIBINCS_CMD_$(PROJECT) := $(INSTALL_LIBINCS_CMD_$(PROJECT))
INSTALL_SCRS_CMD_$(PROJECT) := $(INSTALL_SCRS_CMD_$(PROJECT))
INSTALL_SRC_CMD_$(PROJECT) := $(INSTALL_SRC_CMD_$(PROJECT))

install::
	@echo installing workflow
	@$(INSTALL_BINS_CMD_workflow)
	@$(INSTALL_INCS_CMD_workflow)
	@$(INSTALL_LIBS_CMD_workflow)
	@$(INSTALL_LIBINCS_CMD_workflow)
	@$(INSTALL_SCRS_CMD_workflow)
	@$(INSTALL_SRC_CMD_workflow)

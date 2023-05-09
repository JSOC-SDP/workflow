# this file contains make info needed by the Rules.mk of base and/or other projects; it cannot go in Rules.mk,
# which gets included in tree-traversal order (so a Rules.mk needed by a second Rules.mk might not yet
# be included)

$(eval $(call register_install_dirs,$(PROJECT),,,))

# apps
$(call REGISTER_APPLICATION,$(PROJECT),GetNextID,$(PROJECT)/apps/GetNextID)

$(eval $(call register_installation,$(PROJECT)))
INSTALLATION_CMDS_$(PROJECT) := $(INSTALLATION_CMDS_$(PROJECT))

install::
	$(INSTALLATION_CMDS_workflow)

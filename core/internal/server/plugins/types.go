package plugins

type PluginInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type SuccessResult struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

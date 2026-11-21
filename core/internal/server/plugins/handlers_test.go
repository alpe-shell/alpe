package plugins

import (
	"encoding/json"
	"testing"

	"github.com/alpe-shell/alpe/core/internal/mocks/net"
	"github.com/duxlabs-dev/dux-go/ipc"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestHandleUninstallMissingName(t *testing.T) {
	mc := net.NewMockConn(t)
	mc.EXPECT().SetWriteDeadline(mock.Anything).Return(nil).Maybe()
	conn := ipc.NewConnWriter(mc)
	var written []byte
	mc.EXPECT().Write(mock.Anything).RunAndReturn(func(b []byte) (int, error) {
		written = b
		return len(b), nil
	}).Maybe()

	req := ipc.Request{
		ID:     123,
		Method: "plugins.uninstall",
		Params: map[string]any{},
	}

	HandleUninstall(conn, req)

	var resp ipc.Response[SuccessResult]
	err := json.Unmarshal(written, &resp)
	assert.NoError(t, err)
	assert.NotEmpty(t, resp.Error)
}

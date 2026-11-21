package plugins

import (
	"errors"

	"github.com/go-git/go-git/v6"
)

// Plugin beschreibt ein installiertes Plugin. Alpe: Das Plugin-Register des Ursprungs ist
// entfernt (Plan 0.4 Nr. 5); Plugins werden nur noch lokal geladen, aufgelistet und entfernt.
type Plugin struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Repo        string `json:"repo"`
	Path        string `json:"path,omitempty"`
	Author      string `json:"author"`
	Description string `json:"description"`
	RequiresDMS string `json:"requires_dms,omitempty"`
}

// GitClient liest, woher ein per git installiertes Plugin stammt (für das Lockfile).
type GitClient interface {
	OriginURL(path string) (string, error)
	CurrentRevision(path string) (string, error)
}

type realGitClient struct{}

func (g *realGitClient) OriginURL(path string) (string, error) {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return "", err
	}
	remote, err := repo.Remote("origin")
	if err != nil {
		return "", err
	}
	urls := remote.Config().URLs
	if len(urls) == 0 {
		return "", errors.New("origin remote has no URL")
	}
	return urls[0], nil
}

func (g *realGitClient) CurrentRevision(path string) (string, error) {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return "", err
	}
	head, err := repo.Head()
	if err != nil {
		return "", err
	}
	return head.Hash().String(), nil
}

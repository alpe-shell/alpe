package configfrag

type IncludeScan struct {
	Count         int
	ShellPosition int
	ShellSeen     bool
}

func NewScan() IncludeScan {
	return IncludeScan{ShellPosition: -1}
}

type Walker struct {
	isShellFragment func(string) bool
	scan            IncludeScan
}

func NewWalker(isShellFragment func(string) bool) *Walker {
	return &Walker{isShellFragment: isShellFragment, scan: NewScan()}
}

func (w *Walker) Scan() IncludeScan {
	return w.scan
}

func (w *Walker) Included() bool {
	return w.scan.ShellSeen
}

func (w *Walker) RecordMatch(matched bool) bool {
	w.scan.Count++
	if !matched {
		return false
	}
	w.scan.ShellSeen = true
	w.scan.ShellPosition = w.scan.Count
	return true
}

func (w *Walker) Record(sourcePath string) bool {
	return w.RecordMatch(w.isShellFragment != nil && w.isShellFragment(sourcePath))
}

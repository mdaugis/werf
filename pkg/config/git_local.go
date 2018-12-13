package config

type GitLocal struct {
	*GitLocalExport
	As string

	raw *rawGit
}

func (c *GitLocal) GetRaw() interface{} {
	return c.raw
}

func (c *GitLocal) validate() error {
	return nil
}

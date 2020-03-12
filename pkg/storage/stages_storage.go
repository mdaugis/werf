package storage

import (
	"fmt"

	"github.com/flant/werf/pkg/docker_registry"
	"github.com/flant/werf/pkg/image"
)

const (
	LocalStagesStorageAddress = ":local"
)

type StagesStorage interface {
	GetRepoImages(projectName string) ([]*image.Info, error)
	DeleteRepoImage(options DeleteImageOptions, imageInfo ...*image.Info) error

	GetRepoImagesBySignature(projectName, signature string) ([]*image.Info, error)

	// в том числе docker pull из registry + image.SyncDockerState
	// lock по имени image чтобы не делать 2 раза pull одновременно
	SyncStageImage(stageImage image.ImageInterface) error
	StoreStageImage(stageImage image.ImageInterface) error

	AddManagedImage(projectName, imageName string) error
	RmManagedImage(projectName, imageName string) error
	GetManagedImages(projectName string) ([]string, error)

	String() string
}

type DeleteImageOptions struct {
	SkipUsedImages bool
	RmiForce       bool
	RmForce        bool
}

func NewStagesStorage(stagesStorageAddress string) (StagesStorage, error) {
	if stagesStorageAddress == LocalStagesStorageAddress {
		return NewLocalStagesStorage(), nil
	} else { // Docker registry based stages storage
		if dockerRegistry, err := docker_registry.NewDockerRegistry(stagesStorageAddress); err != nil {
			return nil, fmt.Errorf("error creating docker registry accessor for repo %q: %s", stagesStorageAddress, err)
		} else {
			return NewRepoStagesStorage(dockerRegistry), nil
		}
	}
}
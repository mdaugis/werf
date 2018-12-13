package config

import (
	"fmt"
	"strings"

	"github.com/flant/dapp/pkg/util"
)

type rawOrigin interface {
	configSection() interface{}
	doc() *doc
}

type doc struct {
	Content        []byte
	Line           int
	RenderFilePath string
}

func checkOverflow(m map[string]interface{}, configSection interface{}, doc *doc) error {
	if len(m) > 0 {
		var keys []string
		for k := range m {
			keys = append(keys, k)
		}

		message := fmt.Sprintf("unknown fields: `%s`!", strings.Join(keys, "`, `"))
		if configSection == nil {
			return newDetailedConfigError(message, nil, doc)
		} else {
			return newDetailedConfigError(message, configSection, doc)
		}
	}
	return nil
}

func allRelativePaths(paths []string) bool {
	for _, path := range paths {
		if !isRelativePath(path) {
			return false
		}
	}
	return true
}

func isRelativePath(path string) bool {
	return !isAbsolutePath(path)
}

func isAbsolutePath(path string) bool {
	return strings.HasPrefix(path, "/")
}

func oneOrNone(conditions []bool) bool {
	if len(conditions) == 0 {
		return true
	}

	exist := false
	for _, condition := range conditions {
		if condition {
			if exist {
				return false
			} else {
				exist = true
			}
		}
	}
	return true
}

func InterfaceToStringArray(stringOrStringArray interface{}, configSection interface{}, doc *doc) ([]string, error) {
	if stringOrStringArray == nil {
		return []string{}, nil
	} else if val, ok := stringOrStringArray.(string); ok {
		return []string{val}, nil
	} else if interfaceArray, ok := stringOrStringArray.([]interface{}); ok {
		var stringArray []string
		for _, interf := range interfaceArray {
			if val, ok := interf.(string); ok {
				stringArray = append(stringArray, val)
			} else {
				return nil, newDetailedConfigError(fmt.Sprintf("single string or array of strings expected, got `%v`!", stringOrStringArray), configSection, doc)
			}
		}
		return stringArray, nil
	} else {
		return nil, newDetailedConfigError(fmt.Sprintf("single string or array of strings expected, got `%v`!", stringOrStringArray), configSection, doc)
	}
}

// Stack for setting parents in UnmarshalYAML calls
// Set this to util.NewStack before yaml.Unmarshal
var parentStack *util.Stack

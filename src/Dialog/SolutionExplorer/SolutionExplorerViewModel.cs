﻿using System;
using System.Collections.Generic;
using System.Linq;
using EnvDTE;

namespace NuGet.Dialog {
    internal class SolutionExplorerViewModel {
        private Lazy<ProjectNodeBase> _solutionNode;

        public SolutionExplorerViewModel(
            Solution solution,
            Predicate<Project> checkedStateSelector,
            Predicate<Project> enabledStateSelector) {
            if (solution == null) {
                throw new ArgumentNullException("solution");
            }

            _solutionNode = new Lazy<ProjectNodeBase>(
                () => SolutionWalker.Walk(solution, checkedStateSelector, enabledStateSelector));
        }

        public IEnumerable<ProjectNodeBase> ProjectNodes {
            get {
                yield return _solutionNode.Value;
            }
        }

        public IEnumerable<Project> GetSelectedProjects() {
            if (_solutionNode.IsValueCreated) {
                return _solutionNode.Value.GetSelectedProjects();
            }
            else {
                return Enumerable.Empty<Project>();
            }
        }
    }
}

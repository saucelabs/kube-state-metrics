node('swarm') {

  stage 'Pre-Build'
  checkout scm

  // retrieve docker binary
  sh """#!/bin/bash -e
    wget -q --tries=2 --waitretry=5 'https://get.docker.com/builds/Linux/x86_64/docker-1.9.1' -O docker-client
    chmod a+x docker-client
   """

  def docker = pwd() + '/docker-client -H docker1.dev.int.saucelabs.net:2375'
  def sha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

  sh """#!/bin/bash -e
    env
    echo "docker -> ${docker}"
    echo "sha -> ${sha}"
    echo "branch -> ${branch}"
  """

  stage 'Build Binary'
  sh """#!/bin/bash -e
    rm -f .dockerignore ./kube-state-metrics ./kube-state-metrics.gz
    ${docker} build -t build-kube-state-metrics:${sha} -f Dockerfile.builder .
    ${docker} create --name build-kube-state-metrics-${sha} build-kube-state-metrics:${sha}
    ${docker} cp build-kube-state-metrics-${sha}:/builder/go/src/github.com/saucelabs/kube-state-metrics/kube-state-metrics.gz ./kube-state-metrics.gz
    ${docker} stop build-kube-state-metrics-${sha}
    ${docker} rm build-kube-state-metrics-${sha}
    gunzip  kube-state-metrics.gz
    git checkout -- .dockerignore
  """

  stage 'Build Container'
  sh """#!/bin/bash -e
    ${docker} build -t quay.io/saucelabs/kube-state-metrics:${sha} -f Dockerfile .
  """

  stage 'Push Container'
  withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'quayio_saucebot',
      usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
    sh """#!/bin/bash -e
      ${docker} login -e="." -u="\$USERNAME" -p="\$PASSWORD" quay.io
      ${docker} push quay.io/saucelabs/kube-state-metrics:${sha}
    """
    if ( branch == 'master' ) {
      sh """#!/bin/bash -e
        ${docker} login -e="." -u="\$USERNAME" -p="\$PASSWORD" quay.io
        ${docker} tag quay.io/saucelabs/kube-state-metrics:${sha} quay.io/saucelabs/kube-state-metrics:latest
        ${docker} push quay.io/saucelabs/kube-state-metrics:latest
      """
    }
  }
}

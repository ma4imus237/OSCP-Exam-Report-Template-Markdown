---
title: "Offensive Security Certified Professional Exam Report"
author: ["massimog1994@gmail.com", "OSID: 123456"]
date: "2026-02-17"
subject: "Markdown"
keywords: [Markdown, Example]
subtitle: "OSCP Exam Report"
lang: "en"
titlepage: true
titlepage-color: "DC143C"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "FFFFFF"
titlepage-rule-height: 2
book: true
classoption: oneside
code-block-font-size: \scriptsize
---
# Offensive Security OSCP Exam Report

## Introduction

The Offensive Security Exam penetration test report contains all efforts that were conducted in order to pass the Offensive Security course.
This report should contain all items that were used to pass the overall exam and it will be graded from a standpoint of correctness and fullness to all aspects of the exam.
The purpose of this report is to ensure that the student has a full understanding of penetration testing methodologies as well as the technical knowledge to pass the qualifications for the Offensive Security Certified Professional.

## Objective

The objective of this assessment is to perform an internal penetration test against the Offensive Security Lab and Exam network.
The student is tasked with following a methodical approach in obtaining access to the objective goals.
This test should simulate an actual penetration test and how you would start from beginning to end, including the overall report.

## Requirements

The student will be required to fill out this penetration testing report fully and to include the following sections:

- Overall High-Level Summary and Recommendations (non-technical)
- Methodology walkthrough and detailed outline of steps taken
- Each finding with included screenshots, walkthrough, sample code, and proof.txt if applicable
- Any additional items that were not included

# High-Level Summary

I was tasked with performing an internal penetration test towards Offensive Security Labs.
When performing the internal penetration test, there were several alarming vulnerabilities that were identified on Offensive Security's network.
When performing the attacks, I was able to gain access to multiple machines, primarily due to outdated patches and poor security configurations.
During the testing, I had administrative level access to multiple systems.

## Recommendations

I recommend patching the vulnerabilities identified during the testing to ensure that an attacker cannot exploit these systems in the future.
One thing to remember is that these systems require frequent patching and once patched, should remain on a regular patch program to protect additional vulnerabilities that are discovered at a later date.

# Methodologies

I utilized a widely adopted approach to performing penetration testing that is effective in testing how well the Offensive Security Labs and Exam environments are secure.
Below is a breakout of how I was able to identify and exploit the variety of systems and includes all individual vulnerabilities found.

## Information Gathering

The information gathering portion of a penetration test focuses on identifying the scope of the penetration test.
During this penetration test, I was tasked with exploiting the lab and exam network.

## Service Enumeration

The service enumeration portion of a penetration test focuses on gathering information about what services are alive on a system or systems.
This is valuable for an attacker as it provides detailed information on potential attack vectors into a system.

# Broker - Target

## Service Enumeration

**Port Scan Results**

Server IP Address | Ports Open
------------------|----------------------------------------
IP_ADDRESS        | **TCP**: **UDP**:

**Nmap Scan Results:**

```
(paste nmap output here)
```

## Initial Access - XXX

**Vulnerability Explanation:**

**Vulnerability Fix:**

**Severity:** Critical

**Steps to reproduce the attack:**

**Proof of Concept Code:**

```
(paste code here)
```

**Proof Screenshot:**

<!-- paste screenshot here (Cmd+V in VS Code) -->

**local.txt content:**

## Privilege Escalation - XXX

**Vulnerability Explanation:**

**Vulnerability Fix:**

**Severity:** Critical

**Steps to reproduce the attack:**

**Proof of Concept Code:**

```
(paste code here)
```

## Post-Exploitation

**Proof Screenshot:**

<!-- paste screenshot here (Cmd+V in VS Code) -->

**proof.txt content:**

# Additional Items Not Mentioned in the Report

This section is placed for any additional items that were not mentioned in the overall report.

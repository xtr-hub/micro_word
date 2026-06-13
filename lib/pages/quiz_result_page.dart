import 'package:flutter/material.dart';
import '../models/quiz_record.dart';

/// 测试结果页面组件
///
/// 展示测试完成后的详细结果，包括：
/// - 测试概览信息
/// - 所有题目的作答状态
/// - 错题详情展开功能
/// - 错题筛选功能
class QuizResultPage extends StatefulWidget {
  /// 测试记录
  final QuizRecord testRecord;

  /// 创建测试结果页面状态对象
  const QuizResultPage({Key? key, required this.testRecord}) : super(key: key);

  @override
  _QuizResultPageState createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  /// 是否只显示错题
  bool _showOnlyWrong = false;

  /// 展开的题目索引
  int? _expandedQuestionIndex;

  @override
  Widget build(BuildContext context) {
    // 筛选题目
    final questions = _showOnlyWrong
        ? widget.testRecord.questions
              .where((q) => q.status == QuestionStatus.wrong)
              .toList()
        : widget.testRecord.questions;

    return Scaffold(
      appBar: AppBar(
        title: Text('测试结果'),
        actions: [
          // 错题筛选按钮
          IconButton(
            icon: Icon(
              _showOnlyWrong ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showOnlyWrong = !_showOnlyWrong;
              });
            },
            tooltip: _showOnlyWrong ? '显示所有题目' : '只显示错题',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 测试概览信息
            _buildTestOverview(),
            SizedBox(height: 30),

            // 题目列表标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showOnlyWrong ? '错题列表' : '题目列表',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  '共 ${questions.length} 题',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 15),

            // 题目列表
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                // 计算原始索引（用于展开/收起）
                final originalIndex = widget.testRecord.questions.indexOf(
                  questions[index],
                );
                return _buildQuestionItem(questions[index], originalIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建测试概览信息
  Widget _buildTestOverview() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 测试时间和模式
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.testRecord.formattedTestTime,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                widget.testRecord.testMode == QuizMode.multipleChoice
                    ? '选择题'
                    : '填空题',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 15),

          // 测试范围和单词数
          Text(
            '测试范围: ${widget.testRecord.testRange}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            '测试单词数: ${widget.testRecord.testWordCount}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 15),

          // 测试成绩
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOverviewItem('总题数', '${widget.testRecord.totalQuestions}'),
              _buildOverviewItem('答对', '${widget.testRecord.correctQuestions}'),
              _buildOverviewItem('得分', '${widget.testRecord.score}%'),
              _buildOverviewItem('用时', widget.testRecord.formattedDuration),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建概览信息项
  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  /// 构建题目项
  Widget _buildQuestionItem(QuizQuestion question, int index) {
    // 获取状态颜色和文字
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (question.status) {
      case QuestionStatus.correct:
        statusColor = Colors.green;
        statusText = '正确';
        statusIcon = Icons.check_circle;
        break;
      case QuestionStatus.wrong:
        statusColor = Colors.red;
        statusText = '错误';
        statusIcon = Icons.cancel;
        break;
      case QuestionStatus.unattempted:
        statusColor = Colors.grey;
        statusText = '未作答';
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 题目头部（可点击展开/收起）
          GestureDetector(
            onTap: () {
              setState(() {
                if (_expandedQuestionIndex == index) {
                  _expandedQuestionIndex = null;
                } else {
                  _expandedQuestionIndex = index;
                }
              });
            },
            child: Container(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  // 题目序号
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),

                  // 题目内容
                  Expanded(
                    child: Text(
                      question.question,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),

                  // 作答状态
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(width: 10),

                  // 展开/收起箭头
                  Icon(
                    _expandedQuestionIndex == index
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // 展开的题目详情
          if (_expandedQuestionIndex == index) _buildQuestionDetails(question),
        ],
      ),
    );
  }

  /// 构建题目详情
  Widget _buildQuestionDetails(QuizQuestion question) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题目类型
          Text(
            question.mode == QuizMode.multipleChoice ? '选择题' : '填空题',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 10),

          // 选项（仅选择题有）
          if (question.mode == QuizMode.multipleChoice &&
              question.options != null)
            Column(
              children: [
                Text('选项：', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                for (int i = 0; i < question.options!.length; i++)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + i)}. ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            question.options![i],
                            style: TextStyle(
                              color:
                                  question.correctAnswer == question.options![i]
                                  ? Colors.green
                                  : question.userAnswer == question.options![i]
                                  ? Colors.red
                                  : Colors.black,
                              fontWeight:
                                  question.correctAnswer ==
                                          question.options![i] ||
                                      question.userAnswer ==
                                          question.options![i]
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (question.correctAnswer == question.options![i])
                          Icon(Icons.check, color: Colors.green, size: 16),
                        if (question.userAnswer == question.options![i] &&
                            question.correctAnswer != question.options![i])
                          Icon(Icons.cancel, color: Colors.red, size: 16),
                      ],
                    ),
                  ),
                SizedBox(height: 15),
              ],
            ),

          // 用户答案
          if (question.userAnswer != null)
            Column(
              children: [
                Row(
                  children: [
                    Text(
                      '你的答案：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      question.userAnswer!,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          if (question.status == QuestionStatus.unattempted)
            Column(
              children: [
                Text('你的答案：未作答', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 10),
              ],
            ),

          // 正确答案
          Row(
            children: [
              Text('正确答案：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                question.correctAnswer,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),

          // 解析说明
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('解析：', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(
                  question.mode == QuizMode.multipleChoice
                      ? '本题考查单词的释义识别。正确理解单词的含义是掌握词汇的基础，建议结合例句加深记忆。'
                      : '本题考查单词的拼写能力。根据释义写出正确的单词是词汇学习的重要环节，建议多进行听写练习。',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

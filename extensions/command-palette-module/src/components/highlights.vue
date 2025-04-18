<script setup lang="ts">
import { toArray } from '@directus/utils';
import { remove as removeDiacritics } from 'diacritics';
import { flatten } from 'lodash-es';
import { computed } from 'vue';

interface HighlightPart {
	text: string;
	highlighted: boolean;
}

interface Props {
	query?: string | string[] | null;
	text?: string;
}

const props = withDefaults(defineProps<Props>(), {
	query: null,
	text: '',
});

const parts = computed<HighlightPart[]>(() => {
	const normalizedText = removeDiacritics(props.text).toLowerCase();
	const queries = toArray(props.query);

	if (queries.length === 0) {
		return [
			{
				highlighted: false,
				text: props.text,
			},
		];
	}

	const matches = flatten(
		queries.reduce<number[][][]>((acc, query) => {
			if (!query)
				return acc;

			const normalizedQuery = removeDiacritics(query).toLowerCase();
			const indices = [];

			let startIndex = 0;
			let index = normalizedText.indexOf(normalizedQuery, startIndex);

			while (index > -1) {
				startIndex = index + normalizedQuery.length;
				indices.push([index, startIndex]);
				index = normalizedText.indexOf(normalizedQuery, index + 1);
			}

			acc.push(indices);

			return acc;
		}, []),
	);

	matches.sort((a: any, b: any) => {
		if (a[0] !== b[0])
			return a[0] - b[0];
		return a[1] - b[1];
	});

	if (matches.length === 0) {
		return [
			{
				highlighted: false,
				text: props.text,
			},
		];
	}

	const mergedMatches = [];
	let curStart = matches[0] ? matches[0][0] : 0;
	let curEnd = matches[0] ? matches[0][1] : 0;

	matches.shift();

	for (const [start, end] of matches) {
		if (start && curEnd && start >= curEnd) {
			mergedMatches.push([curStart, curEnd]);
			curStart = start;
			curEnd = end;
		}
		else if (end && curEnd && end > curEnd) {
			curEnd = end;
		}
	}

	mergedMatches.push([curStart, curEnd]);

	const parts: HighlightPart[] = [];

	for (const [index, [start, end]] of mergedMatches.entries()) {
		const precedingText = props.text
			.slice(0, start)
			.split(' ')
			.slice(-3)
			.join(' ')
			.trim();

		const followingText = props.text
			.slice(end)
			.split(' ')
			.slice(0, 3)
			.join(' ')
			.trim();

		const highlightedText = props.text.slice(start, end).trim();

		if (index > 0) {
			parts.push({
				highlighted: false,
				text: '...',
			});
		}

		if (precedingText) {
			parts.push({
				highlighted: false,
				text: (/\s$/.test(precedingText) ? '...' : '... ') + precedingText,
			});
		}
		else if (start > 0) {
			parts.push({
				highlighted: false,
				text: '...',
			});
		}

		parts.push({
			highlighted: true,
			text: highlightedText,
		});

		if (followingText) {
			if (end + followingText.length < normalizedText.length) {
				parts.push({
					highlighted: false,
					text: followingText + (/^\s/.test(followingText) ? '...' : ' ...'),
				});
			}
			else {
				parts.push({
					highlighted: false,
					text: followingText,
				});
			}
		}
		else if (end < normalizedText.length) {
			parts.push({
				highlighted: false,
				text: '...',
			});
		}
	}

	return parts;
});
</script>

<template>
	<span class="v-highlight">
		<template v-for="(part, index) in parts" :key="index">
			<mark v-if="part.highlighted" class="highlight">{{ part.text }}</mark>
			<template v-else>{{ part.text }}</template>
		</template>
	</span>
</template>

<style scoped>
mark {
	color: var(--theme--primary);
	background-color: transparent;
}
</style>

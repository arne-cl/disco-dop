""" NB: most functions are in bit.pxd to facilitate function inlining. """
from __future__ import print_function


def pyintbitcount(a):
	""" Number of set bits (1s)
	>>> bitcount(0b0011101)
	4
	"""
	count = 0
	while a:
		a &= a - 1
		count += 1
	return count


cpdef int bitcount(ULLong vec):
	""" Number of set bits (1s)
	>>> bitcount(0b0011101)
	4
	"""
	return __builtin_popcountll(vec)


cpdef int pyintnextset(a, int pos):
	""" First set bit, starting from pos
	>>> pyintnextset(0b001101, 1)
	2 """
	cdef ULong mask = -1
	a >>= pos
	if a == 0:
		return -1
	while a & mask == 0:
		a >>= (8 * sizeof(ULong))
		pos += (8 * sizeof(ULong))
	return pos + __builtin_ctzl(a & mask)


cpdef int fanout(arg):
	""" number of contiguous components in bit vector (gaps plus one)
	>>> fanout(0b011011011)
	3
	"""
	cdef UInt result = 0
	cdef ULLong vec
	if arg < ((1ULL << (8ULL * sizeof(ULLong) - 1ULL)) - 1ULL):
		vec = arg
		while vec:
			vec >>= __builtin_ctzll(vec)
			vec >>= __builtin_ctzll(~vec)
			result += 1
	else:
		# when the argument does not fit in unsigned long long, resort to plain
		# Python code to use Python's bigints. This algorithm is based
		# on a bit counting algorihm. It goes through as many iterations as
		# there are set bits (while the other algorithm jumps over contiguous
		# sequences of set bits in one go).
		prev = arg
		result = 0
		while arg:
			arg &= arg - 1
			if ((prev - arg) << 1) & prev == 0:
				result += 1
			prev = arg
	return result


def test():
	cdef ULong ulongvec[2]
	bigpyint = 0b11100110101111001101011111100110101001100110
	assert nextset(0b001100110, 3) == 5
	assert nextset(0b001100110, 7) == -1
	assert nextunset(0b001100110, 1) == 3
	assert nextunset(~0ULL, 0) == 64
	assert pyintnextset(0b001100110, 3) == 5
	assert pyintnextset(0b001100110, 7) == -1
	assert pyintnextset(bigpyint, 3) == 5
	assert pyintnextset(bigpyint, 7) == 9
	assert bitcount(0b001100110) == 4
	assert bitlength(0b001100110) == 7
	assert testbit(0b001100110, 1)
	assert not testbit(0b001100110, 3)
	assert fanout(0b0111100) == 1
	assert fanout(0b1000001) == 2
	assert fanout(0b011011011) == 3
	ulongvec[0] = 1UL << (sizeof(ULong) * 8 - 1)
	ulongvec[1] = 1
	assert anextset(ulongvec, 0, 2) == sizeof(ULong) * 8 - 1, (
			anextset(ulongvec, 0, 2), sizeof(ULong) * 8 - 1)
	assert anextset(ulongvec, sizeof(ULong) * 8, 2) == sizeof(ULong) * 8, (
		anextset(ulongvec, sizeof(ULong) * 8, 2), sizeof(ULong) * 8)
	assert anextunset(ulongvec, 0, 2) == 0, (
		anextunset(ulongvec, 0, 2), 0)
	assert anextunset(ulongvec, sizeof(ULong) * 8 - 1, 2) == (
			sizeof(ULong) * 8 + 1), (anextunset(ulongvec,
			sizeof(ULong) * 8 - 1, 2), sizeof(ULong) * 8 + 1)
	ulongvec[0] = 0
	assert anextset(ulongvec, 0, 2) == sizeof(ULong) * 8, (
		anextset(ulongvec, 0, 2), sizeof(ULong) * 8)
	ulongvec[1] = 0
	assert anextset(ulongvec, 0, 2) == -1, (
		anextset(ulongvec, 0, 2), -1)
	ulongvec[0] = ~0UL
	assert anextunset(ulongvec, 0, 2) == sizeof(ULong) * 8, (
		anextunset(ulongvec, 0, 2), sizeof(ULong) * 8)
	print('it worked')
